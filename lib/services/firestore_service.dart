import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/models/shop_model.dart';

/// Firestore service that handles all database operations
/// Manages users and shops collections with real-time updates
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String shopsCollection = 'shops';

  // =====================
  // USER OPERATIONS
  // =====================

  /// Create a new user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id).set(user.toMap());
      debugPrint('User created successfully: ${user.id}');
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user information
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id).update(user.toMap());
      debugPrint('User updated successfully: ${user.id}');
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).delete();
      debugPrint('User deleted successfully: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // =====================
  // SHOP OPERATIONS
  // =====================

  /// Create a new shop document in Firestore
  Future<String> createShop(ShopModel shop) async {
    try {
      DocumentReference docRef = await _firestore.collection(shopsCollection).add(shop.toMap());
      debugPrint('Shop created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating shop: $e');
      rethrow;
    }
  }

  /// Get shop by ID
  Future<ShopModel?> getShop(String shopId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(shopsCollection).doc(shopId).get();
      
      if (doc.exists && doc.data() != null) {
        return ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting shop: $e');
      return null;
    }
  }

  /// Get shops owned by a specific user
  Future<List<ShopModel>> getShopsByOwner(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(shopsCollection)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting shops by owner: $e');
      return [];
    }
  }

  /// Get all shops (with optional filters)
  Future<List<ShopModel>> getAllShops({
    ShopStatus? status,
    String? category,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(shopsCollection);

      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting all shops: $e');
      return [];
    }
  }

  /// Search shops by name or phone number
  Future<List<ShopModel>> searchShops(String searchTerm) async {
    try {
      if (searchTerm.isEmpty) return [];

      // Search by shop name (case insensitive)
      Query nameQuery = _firestore
          .collection(shopsCollection)
          .where('shopName', isGreaterThanOrEqualTo: searchTerm)
          .where('shopName', isLessThan: searchTerm + 'z');

      // Search by phone number
      Query phoneQuery = _firestore
          .collection(shopsCollection)
          .where('phoneNumber', isGreaterThanOrEqualTo: searchTerm)
          .where('phoneNumber', isLessThan: searchTerm + '9');

      // Execute both queries
      List<Future<QuerySnapshot>> futures = [
        nameQuery.get(),
        phoneQuery.get(),
      ];

      List<QuerySnapshot> results = await Future.wait(futures);
      Set<String> addedIds = <String>{}; // To avoid duplicates
      List<ShopModel> shops = [];

      // Combine results and remove duplicates
      for (QuerySnapshot snapshot in results) {
        for (DocumentSnapshot doc in snapshot.docs) {
          if (!addedIds.contains(doc.id)) {
            addedIds.add(doc.id);
            shops.add(ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
          }
        }
      }

      return shops;
    } catch (e) {
      debugPrint('Error searching shops: $e');
      return [];
    }
  }

  /// Update shop information
  Future<void> updateShop(ShopModel shop) async {
    try {
      await _firestore.collection(shopsCollection).doc(shop.id).update(shop.toMap());
      debugPrint('Shop updated successfully: ${shop.id}');
    } catch (e) {
      debugPrint('Error updating shop: $e');
      rethrow;
    }
  }

  /// Update shop status
  Future<void> updateShopStatus(String shopId, ShopStatus status, {bool isManualOverride = false}) async {
    try {
      await _firestore.collection(shopsCollection).doc(shopId).update({
        'status': status.name,
        'isManualOverride': isManualOverride,
        'lastStatusChange': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Shop status updated: $shopId -> ${status.name}');
    } catch (e) {
      debugPrint('Error updating shop status: $e');
      rethrow;
    }
  }

  /// Delete shop document
  Future<void> deleteShop(String shopId) async {
    try {
      await _firestore.collection(shopsCollection).doc(shopId).delete();
      debugPrint('Shop deleted successfully: $shopId');
    } catch (e) {
      debugPrint('Error deleting shop: $e');
      rethrow;
    }
  }

  // =====================
  // REAL-TIME STREAMS
  // =====================

  /// Stream of shops for real-time updates
  Stream<List<ShopModel>> getShopsStream({
    ShopStatus? status,
    String? category,
  }) {
    Query query = _firestore.collection(shopsCollection);

    // Apply filters
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Stream of shops owned by a specific user
  Stream<List<ShopModel>> getOwnerShopsStream(String ownerId) {
    return _firestore
        .collection(shopsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Stream of a specific shop for real-time updates
  Stream<ShopModel?> getShopStream(String shopId) {
    return _firestore
        .collection(shopsCollection)
        .doc(shopId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ShopModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    });
  }

  /// Stream of user data
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    });
  }

  // =====================
  // GEOSPATIAL QUERIES
  // =====================

  /// Get shops within a certain radius of a location
  /// Note: This is a simple implementation. For production, consider using GeoFlutterFire
  Future<List<ShopModel>> getNearbyShops(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    try {
      // Simple bounding box calculation
      double latDelta = radiusInKm / 111.32; // Approximate km per degree latitude
      double lngDelta = radiusInKm / (111.32 * cos(latitude * pi / 180)); // Approximate km per degree longitude

      double minLat = latitude - latDelta;
      double maxLat = latitude + latDelta;
      double minLng = longitude - lngDelta;
      double maxLng = longitude + lngDelta;

      QuerySnapshot querySnapshot = await _firestore
          .collection(shopsCollection)
          .where('location.latitude', isGreaterThanOrEqualTo: minLat)
          .where('location.latitude', isLessThanOrEqualTo: maxLat)
          .get();

      List<ShopModel> shops = querySnapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((shop) => 
              shop.location.longitude >= minLng && 
              shop.location.longitude <= maxLng)
          .toList();

      // Filter by actual distance
      LocationModel userLocation = LocationModel(latitude: latitude, longitude: longitude);
      shops = shops.where((shop) => 
          shop.distanceFrom(userLocation) <= radiusInKm * 1000).toList();

      return shops;
    } catch (e) {
      debugPrint('Error getting nearby shops: $e');
      return [];
    }
  }


}