import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/routes.dart';
import 'package:opennow/widgets/custom_button.dart';
import 'package:opennow/widgets/custom_text_field.dart';

/// Shop registration screen where owners can add new shops
/// Includes shop details form and location picker with Google Maps
class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  late final FirestoreService _firestoreService;
  late final LocationService _locationService;
  
  String? _selectedCategory;
  LocationModel? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _locationService = Provider.of<LocationService>(context, listen: false);
    _getCurrentLocation();
  }

  /// Get current location and update map
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocationWithFallback();
      if (mounted) {
        setState(() {
          _selectedLocation = location;
        });
        _updateMapLocation(location);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Update map camera position
  void _updateMapLocation(LocationModel location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude, location.longitude),
        ),
      );
    }
  }

  /// Handle map tap to select location
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  /// Register new shop
  Future<void> _registerShop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showErrorDialog('Please select shop location on the map');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorDialog('Please select a shop category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        _showErrorDialog('User not found');
        return;
      }

      final shop = ShopModel(
        id: '', // Will be set by Firestore
        ownerId: currentUser.id,
        shopName: _shopNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        category: _selectedCategory!,
        location: _selectedLocation!,
        status: ShopStatus.closed, // Default to closed
        createdAt: DateTime.now(),
      );

      await _firestoreService.createShop(shop);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error registering shop: $e');
      _showErrorDialog('Failed to register shop. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: AppStyles.paddingS),
            Text('Success!'),
          ],
        ),
        content: const Text(AppStrings.shopRegistered),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRoutes.pop(context);
            },
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  /// Validate shop name
  String? _validateShopName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shop name is required';
    }
    if (value.trim().length < 2) {
      return 'Shop name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.registerShop,
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop details section
              _buildShopDetailsSection(),
              
              const SizedBox(height: AppStyles.paddingL),
              
              // Location section
              _buildLocationSection(),
              
              const SizedBox(height: AppStyles.paddingXL),
              
              // Register button
              CustomButton(
                onPressed: _registerShop,
                text: 'Register Shop',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build shop details section
  Widget _buildShopDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Details',
            style: AppStyles.subtitle1,
          ),
          
          const SizedBox(height: AppStyles.paddingM),
          
          // Shop name
          CustomTextField(
            controller: _shopNameController,
            labelText: AppStrings.shopName,
            hintText: 'Enter your shop name',
            validator: _validateShopName,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.store_outlined,
          ),
          
          const SizedBox(height: AppStyles.paddingM),
          
          // Phone number
          CustomTextField(
            controller: _phoneController,
            labelText: AppStrings.phoneNumber,
            hintText: 'Shop contact number',
            validator: _validatePhoneNumber,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.phone_outlined,
          ),
          
          const SizedBox(height: AppStyles.paddingM),
          
          // Category dropdown
          Text(
            AppStrings.shopCategory,
            style: AppStyles.subtitle2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppStyles.paddingS),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Select category',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            items: AppStrings.shopCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.selectLocation,
                style: AppStyles.subtitle1,
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Get current location',
                ),
            ],
          ),
          
          const SizedBox(height: AppStyles.paddingS),
          
          Text(
            'Tap on the map to select your shop location',
            style: AppStyles.body2,
          ),
          
          const SizedBox(height: AppStyles.paddingM),
          
          // Map
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              border: Border.all(color: AppColors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_selectedLocation != null) {
                    _updateMapLocation(_selectedLocation!);
                  }
                },
                initialCameraPosition: _defaultPosition,
                onTap: _onMapTap,
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('shop_location'),
                          position: LatLng(
                            _selectedLocation!.latitude,
                            _selectedLocation!.longitude,
                          ),
                          infoWindow: const InfoWindow(
                            title: 'Shop Location',
                          ),
                        ),
                      }
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          
          if (_selectedLocation != null) ...[
            const SizedBox(height: AppStyles.paddingM),
            Container(
              padding: const EdgeInsets.all(AppStyles.paddingS),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.success,
                    size: AppStyles.iconS,
                  ),
                  const SizedBox(width: AppStyles.paddingS),
                  Expanded(
                    child: Text(
                      'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}