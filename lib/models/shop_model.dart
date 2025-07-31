import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ShopStatus { open, closed }

class ShopModel {
  final String id;
  final String ownerId;
  final String shopName;
  final String phone;
  final String category;
  final GeoPoint location;
  final ShopStatus status;
  final bool isManualOverride;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ShopModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.phone,
    required this.category,
    required this.location,
    required this.status,
    this.isManualOverride = false,
    required this.createdAt,
    required this.lastUpdated,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'shopName': shopName,
      'phone': phone,
      'category': category,
      'location': location,
      'status': status.name,
      'isManualOverride': isManualOverride,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  // Create from Firestore document
  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      shopName: data['shopName'] ?? '',
      phone: data['phone'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      status: ShopStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ShopStatus.closed,
      ),
      isManualOverride: data['isManualOverride'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Create from Map
  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      shopName: map['shopName'] ?? '',
      phone: map['phone'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? const GeoPoint(0, 0),
      status: ShopStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ShopStatus.closed,
      ),
      isManualOverride: map['isManualOverride'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Convert to LatLng for Google Maps
  LatLng get latLng => LatLng(location.latitude, location.longitude);

  // Check if shop is open
  bool get isOpen => status == ShopStatus.open;

  // Copy with method
  ShopModel copyWith({
    String? id,
    String? ownerId,
    String? shopName,
    String? phone,
    String? category,
    GeoPoint? location,
    ShopStatus? status,
    bool? isManualOverride,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ShopModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'ShopModel(id: $id, shopName: $shopName, status: $status, location: $location)';
  }
}