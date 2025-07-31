import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../models/shop_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _categoryController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  String? _selectedCategory;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _categoryController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLocationLoading = false;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: AppColors.closedRed,
          ),
        );
      }
    }
  }

  Future<void> _registerShop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location for your shop'),
          backgroundColor: AppColors.closedRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create shop model
      final shop = ShopModel(
        id: '', // Will be set by Firestore
        ownerId: user.id,
        shopName: _shopNameController.text.trim(),
        phone: _shopPhoneController.text.trim(),
        category: _selectedCategory ?? '',
        location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        status: ShopStatus.closed,
        isManualOverride: false,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Save to Firestore
      final shopId = await _firestoreService.createShop(shop);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop registered successfully!'),
            backgroundColor: AppColors.openGreen,
          ),
        );
        
        // Navigate back to dashboard
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering shop: ${e.toString()}'),
            backgroundColor: AppColors.closedRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Category',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: AppStrings.shopCategories.length,
                itemBuilder: (context, index) {
                  final category = AppStrings.shopCategories[index];
                  return ListTile(
                    title: Text(category),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _categoryController.text = category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.registerShopTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Name
              CustomTextField(
                controller: _shopNameController,
                hintText: AppStrings.shopNameHint,
                prefixIcon: Icons.store,
                validator: Validators.validateShopName,
              ),
              
              const SizedBox(height: 20),
              
              // Shop Phone
              CustomTextField(
                controller: _shopPhoneController,
                hintText: AppStrings.shopPhoneHint,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validateShopPhone,
              ),
              
              const SizedBox(height: 20),
              
              // Category
              CustomTextField(
                controller: _categoryController,
                hintText: AppStrings.shopCategoryHint,
                prefixIcon: Icons.category,
                readOnly: true,
                onTap: _showCategoryPicker,
                validator: Validators.validateCategory,
              ),
              
              const SizedBox(height: 30),
              
              // Location Section
              Text(
                AppStrings.selectLocation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Map Container
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? const LatLng(0, 0),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: (latLng) {
                          setState(() {
                            _selectedLocation = latLng;
                          });
                        },
                        markers: _selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('shop_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(
                                    title: 'Shop Location',
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                      
                      // Current Location Button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: _getCurrentLocation,
                          backgroundColor: AppColors.primary,
                          child: _isLocationLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Location Info
              if (_selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Register Button
              CustomButton(
                text: _isLoading ? 'Registering...' : AppStrings.registerButton,
                onPressed: _isLoading ? null : _registerShop,
                isLoading: _isLoading,
                icon: Icons.add_business,
              ),
              
              const SizedBox(height: 20),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your shop will be set to CLOSED by default. It will automatically switch to OPEN when you are within 50 meters of the shop location.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}