import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:opennow/models/shop_model.dart';

/// Location service that handles device location tracking and permissions
/// Provides current location, distance calculation, and location monitoring
class LocationService {
  static const double defaultLatitude = 37.7749; // Default to San Francisco
  static const double defaultLongitude = -122.4194;

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from user
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Check if we have sufficient location permissions
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await checkLocationPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Get current device location
  /// Returns null if location cannot be obtained
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check/request permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get current location with fallback to default location
  Future<LocationModel> getCurrentLocationWithFallback() async {
    LocationModel? location = await getCurrentLocation();
    return location ?? const LocationModel(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
    );
  }

  /// Calculate distance between two locations in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate distance from current location to a shop
  Future<double?> distanceToShop(ShopModel shop) async {
    LocationModel? currentLocation = await getCurrentLocation();
    if (currentLocation == null) return null;

    return calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      shop.location.latitude,
      shop.location.longitude,
    );
  }

  /// Check if current location is within a certain radius of a target location
  Future<bool> isWithinRadius(
    LocationModel targetLocation,
    double radiusInMeters,
  ) async {
    LocationModel? currentLocation = await getCurrentLocation();
    if (currentLocation == null) return false;

    double distance = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    return distance <= radiusInMeters;
  }

  /// Get location stream for real-time tracking
  /// Note: This requires location permissions and may drain battery
  Stream<LocationModel> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Minimum distance in meters before update
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LocationModel(
              latitude: position.latitude,
              longitude: position.longitude,
            ));
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission management)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Check if background location permission is granted (Android)
  Future<bool> hasBackgroundLocationPermission() async {
    try {
      PermissionStatus status = await Permission.locationAlways.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking background location permission: $e');
      return false;
    }
  }

  /// Request background location permission (Android)
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      PermissionStatus status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting background location permission: $e');
      return false;
    }
  }

  /// Get location accuracy information
  Future<LocationAccuracyStatus> getLocationAccuracy() async {
    try {
      return await Geolocator.getLocationAccuracy();
    } catch (e) {
      debugPrint('Error getting location accuracy: $e');
      return LocationAccuracyStatus.unknown;
    }
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  /// Get address from coordinates (reverse geocoding)
  /// Note: This requires geocoding package and may have usage limits
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // TODO: Implement reverse geocoding using geocoding package
      // List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      // if (placemarks.isNotEmpty) {
      //   Placemark place = placemarks.first;
      //   return '${place.street}, ${place.locality}, ${place.country}';
      // }
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      // TODO: Implement forward geocoding using geocoding package
      // List<Location> locations = await locationFromAddress(address);
      // if (locations.isNotEmpty) {
      //   Location location = locations.first;
      //   return LocationModel(latitude: location.latitude, longitude: location.longitude);
      // }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Dispose location service resources
  void dispose() {
    // Clean up any streams or resources if needed
  }
}