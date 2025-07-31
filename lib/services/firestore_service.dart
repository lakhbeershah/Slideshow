import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/shop_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Shop Collection Reference
  CollectionReference get _shopsCollection => _firestore.collection('shops');
  
  // User Collection Reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create a new shop
  Future<String> createShop(ShopModel shop) async {
    try {
      DocumentReference docRef = await _shopsCollection.add(shop.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating shop: $e');
      throw Exception('Failed to create shop');
    }
  }

  // Get shop by owner ID
  Future<ShopModel?> getShopByOwnerId(String ownerId) async {
    try {
      QuerySnapshot query = await _shopsCollection
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return ShopModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting shop by owner ID: $e');
      return null;
    }
  }

  // Update shop status
  Future<bool> updateShopStatus(String shopId, ShopStatus status, {bool isManualOverride = false}) async {
    try {
      await _shopsCollection.doc(shopId).update({
        'status': status.name,
        'isManualOverride': isManualOverride,
        'lastUpdated': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error updating shop status: $e');
      return false;
    }
  }

  // Get all shops (for customers)
  Stream<List<ShopModel>> getAllShops() {
    return _shopsCollection
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ShopModel.fromFirestore(doc))
              .toList();
        });
  }

  // Search shops by name or phone
  Future<List<ShopModel>> searchShops(String query) async {
    try {
      // Search by shop name
      QuerySnapshot nameQuery = await _shopsCollection
          .where('shopName', isGreaterThanOrEqualTo: query)
          .where('shopName', isLessThan: query + '\uf8ff')
          .get();

      // Search by phone number
      QuerySnapshot phoneQuery = await _shopsCollection
          .where('phone', isGreaterThanOrEqualTo: query)
          .where('phone', isLessThan: query + '\uf8ff')
          .get();

      // Combine and deduplicate results
      Set<String> seenIds = {};
      List<ShopModel> results = [];

      for (var doc in nameQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(ShopModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      for (var doc in phoneQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(ShopModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      print('Error searching shops: $e');
      return [];
    }
  }

  // Get shops within radius (for geofencing)
  Future<List<ShopModel>> getShopsWithinRadius(Position center, double radiusInMeters) async {
    try {
      // Calculate bounding box for the radius
      double lat = center.latitude;
      double lon = center.longitude;
      
      // Approximate degrees per meter at the equator
      double latDelta = radiusInMeters / 111320.0;
      double lonDelta = radiusInMeters / (111320.0 * cos(lat * pi / 180));
      
      double minLat = lat - latDelta;
      double maxLat = lat + latDelta;
      double minLon = lon - lonDelta;
      double maxLon = lon + lonDelta;

      QuerySnapshot query = await _shopsCollection
          .where('location', isGreaterThan: GeoPoint(minLat, minLon))
          .where('location', isLessThan: GeoPoint(maxLat, maxLon))
          .get();

      List<ShopModel> shops = [];
      for (var doc in query.docs) {
        ShopModel shop = ShopModel.fromFirestore(doc);
        double distance = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          shop.location.latitude,
          shop.location.longitude,
        );
        
        if (distance <= radiusInMeters) {
          shops.add(shop);
        }
      }

      return shops;
    } catch (e) {
      print('Error getting shops within radius: $e');
      return [];
    }
  }

  // Update user data
  Future<bool> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toMap());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Delete shop (for testing/cleanup)
  Future<bool> deleteShop(String shopId) async {
    try {
      await _shopsCollection.doc(shopId).delete();
      return true;
    } catch (e) {
      print('Error deleting shop: $e');
      return false;
    }
  }

  // Get shops with real-time updates
  Stream<List<ShopModel>> getShopsStream({bool openOnly = false}) {
    Query query = _shopsCollection.orderBy('lastUpdated', descending: true);
    
    if (openOnly) {
      query = query.where('status', isEqualTo: ShopStatus.open.name);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ShopModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get shop with real-time updates
  Stream<ShopModel?> getShopStream(String shopId) {
    return _shopsCollection
        .doc(shopId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return ShopModel.fromFirestore(doc);
          }
          return null;
        });
  }
}