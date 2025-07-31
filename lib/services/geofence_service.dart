import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/services/firestore_service.dart';

/// Geofencing service that handles automatic shop status updates
/// Monitors shop owner location and updates shop status when entering/leaving shop area
class GeofenceService with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Geofencing constants
  static const double shopRadiusMeters = 50.0; // 50 meter radius for shop detection
  static const String backgroundTaskName = 'geofenceTask';
  static const int locationCheckIntervalMinutes = 5; // Check location every 5 minutes
  
  // Current state
  bool _isMonitoring = false;
  StreamSubscription<LocationModel>? _locationSubscription;
  List<ShopModel> _monitoredShops = [];
  LocationModel? _lastKnownLocation;
  
  // Getters
  bool get isMonitoring => _isMonitoring;
  List<ShopModel> get monitoredShops => _monitoredShops;
  LocationModel? get lastKnownLocation => _lastKnownLocation;

  /// Initialize the geofencing service
  GeofenceService() {
    _initializeWorkManager();
  }

  /// Initialize WorkManager for background tasks
  void _initializeWorkManager() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Start monitoring location for a shop owner
  Future<bool> startMonitoring(UserModel user) async {
    if (!user.isOwner) {
      debugPrint('Cannot start monitoring: User is not a shop owner');
      return false;
    }

    try {
      // Check location permissions
      bool hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return false;
      }

      // Get user's shops
      _monitoredShops = await _firestoreService.getShopsByOwner(user.id);
      if (_monitoredShops.isEmpty) {
        debugPrint('No shops found for owner: ${user.id}');
        return false;
      }

      // Start location monitoring
      await _startLocationMonitoring();
      
      // Register background task
      await _registerBackgroundTask();
      
      _isMonitoring = true;
      notifyListeners();
      
      debugPrint('Geofencing started for ${_monitoredShops.length} shops');
      return true;
    } catch (e) {
      debugPrint('Error starting geofencing: $e');
      return false;
    }
  }

  /// Stop monitoring location
  Future<void> stopMonitoring() async {
    try {
      // Cancel location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      
      // Cancel background tasks
      await Workmanager().cancelAll();
      
      _isMonitoring = false;
      _monitoredShops.clear();
      _lastKnownLocation = null;
      
      notifyListeners();
      debugPrint('Geofencing stopped');
    } catch (e) {
      debugPrint('Error stopping geofencing: $e');
    }
  }

  /// Start location monitoring stream
  Future<void> _startLocationMonitoring() async {
    _locationSubscription = _locationService.getLocationStream(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    ).listen(
      (location) => _onLocationUpdate(location),
      onError: (error) => debugPrint('Location stream error: $error'),
    );
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(LocationModel newLocation) async {
    _lastKnownLocation = newLocation;
    
    try {
      // Check each monitored shop
      for (ShopModel shop in _monitoredShops) {
        double distance = _locationService.calculateDistance(
          newLocation.latitude,
          newLocation.longitude,
          shop.location.latitude,
          shop.location.longitude,
        );
        
        bool isNearShop = distance <= shopRadiusMeters;
        bool shouldBeOpen = isNearShop && !shop.isManualOverride;
        bool shouldBeClosed = !isNearShop && !shop.isManualOverride;
        
        // Update shop status if needed
        if (shouldBeOpen && shop.status != ShopStatus.open) {
          await _updateShopStatus(shop.id, ShopStatus.open, isAutomatic: true);
          debugPrint('Shop ${shop.shopName} automatically opened (distance: ${distance.round()}m)');
        } else if (shouldBeClosed && shop.status != ShopStatus.closed) {
          await _updateShopStatus(shop.id, ShopStatus.closed, isAutomatic: true);
          debugPrint('Shop ${shop.shopName} automatically closed (distance: ${distance.round()}m)');
        }
      }
    } catch (e) {
      debugPrint('Error processing location update: $e');
    }
  }

  /// Update shop status in Firestore
  Future<void> _updateShopStatus(String shopId, ShopStatus status, {bool isAutomatic = false}) async {
    try {
      await _firestoreService.updateShopStatus(
        shopId,
        status,
        isManualOverride: !isAutomatic,
      );
      
      // Update local shop list
      int shopIndex = _monitoredShops.indexWhere((shop) => shop.id == shopId);
      if (shopIndex != -1) {
        _monitoredShops[shopIndex] = _monitoredShops[shopIndex].copyWith(
          status: status,
          isManualOverride: !isAutomatic,
          lastStatusChange: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating shop status: $e');
    }
  }

  /// Manually toggle shop status (override automatic behavior)
  Future<bool> toggleShopStatus(String shopId) async {
    try {
      int shopIndex = _monitoredShops.indexWhere((shop) => shop.id == shopId);
      if (shopIndex == -1) {
        debugPrint('Shop not found in monitored shops');
        return false;
      }

      ShopModel shop = _monitoredShops[shopIndex];
      ShopStatus newStatus = shop.isOpen ? ShopStatus.closed : ShopStatus.open;
      
      await _updateShopStatus(shopId, newStatus, isAutomatic: false);
      debugPrint('Shop ${shop.shopName} manually toggled to ${newStatus.name}');
      
      return true;
    } catch (e) {
      debugPrint('Error toggling shop status: $e');
      return false;
    }
  }

  /// Clear manual override and return to automatic mode
  Future<bool> clearManualOverride(String shopId) async {
    try {
      int shopIndex = _monitoredShops.indexWhere((shop) => shop.id == shopId);
      if (shopIndex == -1) return false;

      ShopModel shop = _monitoredShops[shopIndex].copyWith(
        isManualOverride: false,
        lastStatusChange: DateTime.now(),
      );

      await _firestoreService.updateShop(shop);
      _monitoredShops[shopIndex] = shop;
      
      // Trigger immediate location check to update status
      if (_lastKnownLocation != null) {
        await _onLocationUpdate(_lastKnownLocation!);
      }
      
      notifyListeners();
      debugPrint('Manual override cleared for shop ${shop.shopName}');
      return true;
    } catch (e) {
      debugPrint('Error clearing manual override: $e');
      return false;
    }
  }

  /// Register background task for location monitoring
  Future<void> _registerBackgroundTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        backgroundTaskName,
        backgroundTaskName,
        frequency: Duration(minutes: locationCheckIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      debugPrint('Background task registered');
    } catch (e) {
      debugPrint('Error registering background task: $e');
    }
  }

  /// Check if owner is near any of their shops
  Future<ShopModel?> getNearestOwnedShop(String ownerId) async {
    try {
      LocationModel? currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation == null) return null;

      List<ShopModel> ownerShops = await _firestoreService.getShopsByOwner(ownerId);
      
      ShopModel? nearestShop;
      double nearestDistance = double.infinity;
      
      for (ShopModel shop in ownerShops) {
        double distance = _locationService.calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          shop.location.latitude,
          shop.location.longitude,
        );
        
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestShop = shop;
        }
      }
      
      // Return shop only if within the geofence radius
      if (nearestShop != null && nearestDistance <= shopRadiusMeters) {
        return nearestShop;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting nearest owned shop: $e');
      return null;
    }
  }

  /// Get distance to a specific shop
  Future<double?> getDistanceToShop(String shopId) async {
    try {
      ShopModel? shop = await _firestoreService.getShop(shopId);
      if (shop == null) return null;
      
      return await _locationService.distanceToShop(shop);
    } catch (e) {
      debugPrint('Error getting distance to shop: $e');
      return null;
    }
  }

  /// Check if location permissions are sufficient for geofencing
  Future<bool> checkPermissions() async {
    bool locationPermission = await _locationService.hasLocationPermission();
    bool backgroundPermission = await _locationService.hasBackgroundLocationPermission();
    
    return locationPermission && backgroundPermission;
  }

  /// Request all necessary permissions for geofencing
  Future<bool> requestPermissions() async {
    // Request location permission first
    bool locationGranted = await _locationService.hasLocationPermission();
    if (!locationGranted) {
      await _locationService.requestLocationPermission();
      locationGranted = await _locationService.hasLocationPermission();
    }
    
    // Request background location permission
    bool backgroundGranted = await _locationService.hasBackgroundLocationPermission();
    if (!backgroundGranted) {
      backgroundGranted = await _locationService.requestBackgroundLocationPermission();
    }
    
    return locationGranted && backgroundGranted;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

/// Background task dispatcher for WorkManager
/// This function runs in a separate isolate for background processing
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background geofence task started: $task');
      
      // TODO: Implement background location checking
      // This would involve:
      // 1. Getting current location
      // 2. Checking against registered geofences
      // 3. Updating shop statuses if needed
      // 4. Sending notifications if required
      
      debugPrint('Background geofence task completed');
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}