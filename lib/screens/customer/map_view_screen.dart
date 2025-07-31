import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/widgets/shop_card.dart';

/// Map view screen showing shops on Google Maps
/// Displays shops as markers with color coding for open/closed status
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late final FirestoreService _firestoreService;
  late final LocationService _locationService;
  
  GoogleMapController? _mapController;
  List<ShopModel> _shops = [];
  Set<Marker> _markers = {};
  ShopModel? _selectedShop;
  LocationModel? _currentLocation;
  bool _isLoading = true;
  bool _showOnlyOpen = false;

  // Default map position (San Francisco)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _locationService = Provider.of<LocationService>(context, listen: false);
    _initializeMap();
  }

  /// Initialize map data
  Future<void> _initializeMap() async {
    await Future.wait([
      _getCurrentLocation(),
      _loadShops(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentLocationWithFallback();
      if (_currentLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  /// Load shops and create markers
  Future<void> _loadShops() async {
    try {
      // Listen to real-time shop updates
      _firestoreService.getShopsStream().listen((shops) {
        setState(() {
          _shops = _showOnlyOpen 
              ? shops.where((shop) => shop.status == ShopStatus.open).toList()
              : shops;
          _updateMarkers();
        });
      });
    } catch (e) {
      debugPrint('Error loading shops: $e');
    }
  }

  /// Update map markers based on current shops
  void _updateMarkers() {
    _markers.clear();

    for (final shop in _shops) {
      final markerId = MarkerId(shop.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(shop.location.latitude, shop.location.longitude),
        infoWindow: InfoWindow(
          title: shop.shopName,
          snippet: '${shop.category} • ${shop.statusText}',
          onTap: () => _selectShop(shop),
        ),
        icon: _getMarkerIcon(shop.status),
        onTap: () => _selectShop(shop),
      );
      _markers.add(marker);
    }

    setState(() {});
  }

  /// Get marker icon based on shop status
  BitmapDescriptor _getMarkerIcon(ShopStatus status) {
    switch (status) {
      case ShopStatus.open:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ShopStatus.closed:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ShopStatus.unknown:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  /// Select a shop and show details
  void _selectShop(ShopModel shop) {
    setState(() {
      _selectedShop = shop;
    });

    // Animate camera to shop location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(shop.location.latitude, shop.location.longitude),
          15,
        ),
      );
    }
  }

  /// Move camera to user's current location
  void _moveToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          15,
        ),
      );
    } else {
      // Get fresh location
      await _getCurrentLocation();
    }
  }

  /// Toggle open shops only filter
  void _toggleOpenShopsFilter() {
    setState(() {
      _showOnlyOpen = !_showOnlyOpen;
      _selectedShop = null;
    });
    _loadShops();
  }

  /// Calculate distance to selected shop
  Future<double?> _calculateDistance() async {
    if (_selectedShop == null || _currentLocation == null) return null;
    
    return _locationService.calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _selectedShop!.location.latitude,
      _selectedShop!.location.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Shop Map',
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Filter toggle
          IconButton(
            onPressed: _toggleOpenShopsFilter,
            icon: Icon(
              _showOnlyOpen ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showOnlyOpen ? AppColors.primary : null,
            ),
            tooltip: 'Show open shops only',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_currentLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                        ),
                      );
                    }
                  },
                  initialCameraPosition: _defaultPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: (LatLng position) {
                    // Deselect shop when tapping empty area
                    setState(() {
                      _selectedShop = null;
                    });
                  },
                ),

                // Filter indicator
                if (_showOnlyOpen)
                  Positioned(
                    top: AppStyles.paddingM,
                    left: AppStyles.paddingM,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.paddingM,
                        vertical: AppStyles.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppStyles.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: AppStyles.iconS,
                          ),
                          SizedBox(width: AppStyles.paddingXS),
                          Text(
                            'Open Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Legend
                Positioned(
                  top: AppStyles.paddingM,
                  right: AppStyles.paddingM,
                  child: Container(
                    padding: const EdgeInsets.all(AppStyles.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legend',
                          style: AppStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppStyles.paddingXS),
                        _buildLegendItem(
                          color: AppColors.shopOpen,
                          label: 'Open',
                        ),
                        const SizedBox(height: AppStyles.paddingXS),
                        _buildLegendItem(
                          color: AppColors.shopClosed,
                          label: 'Closed',
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected shop details
                if (_selectedShop != null)
                  Positioned(
                    bottom: AppStyles.paddingM,
                    left: AppStyles.paddingM,
                    right: AppStyles.paddingM,
                    child: FutureBuilder<double?>(
                      future: _calculateDistance(),
                      builder: (context, snapshot) {
                        return ShopCard(
                          shop: _selectedShop!,
                          distance: snapshot.data,
                          onTap: () {
                            // TODO: Navigate to shop details
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  /// Build legend item
  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppStyles.paddingS),
        Text(
          label,
          style: AppStyles.caption,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}