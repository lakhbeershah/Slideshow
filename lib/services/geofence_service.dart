import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/shop_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class GeofenceService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  StreamSubscription<Position>? _locationSubscription;
  ShopModel? _currentShop;
  bool _isGeofencingActive = false;
  Timer? _statusCheckTimer;
  
  // Geofencing settings
  static const double _shopRadius = 50.0; // 50 meters
  static const Duration _statusCheckInterval = Duration(seconds: 30);

  // Getters
  ShopModel? get currentShop => _currentShop;
  bool get isGeofencingActive => _isGeofencingActive;

  // Initialize geofencing for shop owner
  Future<void> initializeGeofencing(String ownerId) async {
    try {
      // Get shop data
      _currentShop = await _firestoreService.getShopByOwnerId(ownerId);
      
      if (_currentShop != null) {
        await _startLocationTracking();
        _startStatusCheckTimer();
        _isGeofencingActive = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing geofencing: $e');
    }
  }

  // Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      _locationSubscription = _locationService.getLocationStream().listen(
        (Position position) {
          _checkShopStatus(position);
        },
        onError: (error) {
          print('Location stream error: $error');
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  // Check shop status based on owner location
  void _checkShopStatus(Position ownerPosition) {
    if (_currentShop == null) return;

    double distance = _locationService.calculateDistanceToCoordinates(
      ownerPosition,
      _currentShop!.location.latitude,
      _currentShop!.location.longitude,
    );

    ShopStatus newStatus = distance <= _shopRadius 
        ? ShopStatus.open 
        : ShopStatus.closed;

    // Only update if status changed and not manually overridden
    if (newStatus != _currentShop!.status && !_currentShop!.isManualOverride) {
      _updateShopStatus(newStatus);
    }
  }

  // Update shop status in Firestore
  Future<void> _updateShopStatus(ShopStatus status) async {
    if (_currentShop == null) return;

    try {
      bool success = await _firestoreService.updateShopStatus(
        _currentShop!.id,
        status,
        isManualOverride: false,
      );

      if (success) {
        _currentShop = _currentShop!.copyWith(
          status: status,
          isManualOverride: false,
          lastUpdated: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating shop status: $e');
    }
  }

  // Manual status override
  Future<bool> setManualStatus(ShopStatus status) async {
    if (_currentShop == null) return false;

    try {
      bool success = await _firestoreService.updateShopStatus(
        _currentShop!.id,
        status,
        isManualOverride: true,
      );

      if (success) {
        _currentShop = _currentShop!.copyWith(
          status: status,
          isManualOverride: true,
          lastUpdated: DateTime.now(),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting manual status: $e');
      return false;
    }
  }

  // Start periodic status check timer
  void _startStatusCheckTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(_statusCheckInterval, (timer) async {
      Position? currentPosition = await _locationService.getCurrentLocation();
      if (currentPosition != null) {
        _checkShopStatus(currentPosition);
      }
    });
  }

  // Stop geofencing
  void stopGeofencing() {
    _locationSubscription?.cancel();
    _statusCheckTimer?.cancel();
    _isGeofencingActive = false;
    _currentShop = null;
    notifyListeners();
  }

  // Check if owner is at shop location
  Future<bool> isOwnerAtShop() async {
    if (_currentShop == null) return false;

    Position? currentPosition = await _locationService.getCurrentLocation();
    if (currentPosition == null) return false;

    double distance = _locationService.calculateDistanceToCoordinates(
      currentPosition,
      _currentShop!.location.latitude,
      _currentShop!.location.longitude,
    );

    return distance <= _shopRadius;
  }

  // Get distance to shop
  Future<double?> getDistanceToShop() async {
    if (_currentShop == null) return null;

    Position? currentPosition = await _locationService.getCurrentLocation();
    if (currentPosition == null) return null;

    return _locationService.calculateDistanceToCoordinates(
      currentPosition,
      _currentShop!.location.latitude,
      _currentShop!.location.longitude,
    );
  }

  // Refresh shop data
  Future<void> refreshShopData() async {
    if (_currentShop == null) return;

    try {
      ShopModel? updatedShop = await _firestoreService.getShopByOwnerId(_currentShop!.ownerId);
      if (updatedShop != null) {
        _currentShop = updatedShop;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing shop data: $e');
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // Get geofencing status description
  String getGeofencingStatusDescription() {
    if (_currentShop == null) {
      return 'No shop registered';
    }

    if (_currentShop!.isManualOverride) {
      return 'Manual override active';
    }

    if (_currentShop!.isOpen) {
      return 'Shop is OPEN (location-based)';
    } else {
      return 'Shop is CLOSED (location-based)';
    }
  }

  // Get shop radius in meters
  double get shopRadius => _shopRadius;

  // Check if geofencing is properly set up
  bool get isProperlyConfigured {
    return _currentShop != null && _isGeofencingActive;
  }
}