import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shop status enumeration
enum ShopStatus { open, closed, unknown }

/// Location model for storing latitude and longitude
class LocationModel {
  final double latitude;
  final double longitude;

  const LocationModel({
    required this.latitude,
    required this.longitude,
  });

  /// Creates LocationModel from a Map
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  /// Converts LocationModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() => 'LocationModel(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Shop model representing a shop in the system
class ShopModel {
  final String id;
  final String ownerId;
  final String shopName;
  final String phoneNumber;
  final String category;
  final LocationModel location;
  final ShopStatus status;
  final bool isManualOverride;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastStatusChange;

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.phoneNumber,
    required this.category,
    required this.location,
    required this.status,
    this.isManualOverride = false,
    required this.createdAt,
    this.updatedAt,
    this.lastStatusChange,
  });

  /// Creates a ShopModel from a Map (typically from Firestore)
  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      shopName: map['shopName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      category: map['category'] ?? '',
      location: LocationModel.fromMap(map['location'] ?? {}),
      status: _statusFromString(map['status'] ?? ''),
      isManualOverride: map['isManualOverride'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      lastStatusChange: (map['lastStatusChange'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts ShopModel to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'shopName': shopName,
      'phoneNumber': phoneNumber,
      'category': category,
      'location': location.toMap(),
      'status': status.name,
      'isManualOverride': isManualOverride,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastStatusChange': lastStatusChange != null 
          ? Timestamp.fromDate(lastStatusChange!) 
          : null,
    };
  }

  /// Creates a copy of the shop with updated fields
  ShopModel copyWith({
    String? id,
    String? ownerId,
    String? shopName,
    String? phoneNumber,
    String? category,
    LocationModel? location,
    ShopStatus? status,
    bool? isManualOverride,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastStatusChange,
  }) {
    return ShopModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopName: shopName ?? this.shopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastStatusChange: lastStatusChange ?? this.lastStatusChange,
    );
  }

  /// Helper method to convert string to ShopStatus enum
  static ShopStatus _statusFromString(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'open':
        return ShopStatus.open;
      case 'closed':
        return ShopStatus.closed;
      default:
        return ShopStatus.unknown;
    }
  }

  /// Check if shop is currently open
  bool get isOpen => status == ShopStatus.open;

  /// Check if shop is currently closed
  bool get isClosed => status == ShopStatus.closed;

  /// Get status as display string
  String get statusText {
    switch (status) {
      case ShopStatus.open:
        return 'OPEN';
      case ShopStatus.closed:
        return 'CLOSED';
      case ShopStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// Calculate distance from given location (in meters)
  /// Uses Haversine formula for distance calculation
  double distanceFrom(LocationModel otherLocation) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double lat1Rad = location.latitude * (3.14159265359 / 180);
    double lat2Rad = otherLocation.latitude * (3.14159265359 / 180);
    double deltaLatRad = (otherLocation.latitude - location.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (otherLocation.longitude - location.longitude) * (3.14159265359 / 180);

    double a = (sin(deltaLatRad / 2) * sin(deltaLatRad / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  String toString() {
    return 'ShopModel(id: $id, shopName: $shopName, status: $status, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopModel &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.shopName == shopName &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        shopName.hashCode ^
        status.hashCode;
  }
}

