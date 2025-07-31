import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../models/shop_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/geofence_service.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_indicator.dart';
import 'register_shop_screen.dart';
import '../profile/profile_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  ShopModel? _shop;
  bool _isLoading = true;
  bool _isManualOverride = false;
  double? _distanceToShop;

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _initializeGeofencing();
  }

  Future<void> _loadShopData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user != null) {
        final shop = await _firestoreService.getShopByOwnerId(user.id);
        if (mounted) {
          setState(() {
            _shop = shop;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeGeofencing() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user != null) {
        final geofenceService = Provider.of<GeofenceService>(context, listen: false);
        await geofenceService.initializeGeofencing(user.id);
        
        // Update distance to shop
        _updateDistanceToShop();
      }
    } catch (e) {
      print('Error initializing geofencing: $e');
    }
  }

  Future<void> _updateDistanceToShop() async {
    if (_shop == null) return;

    try {
      final distance = await _locationService.getDistanceToCoordinates(
        await _locationService.getCurrentLocation(),
        _shop!.location.latitude,
        _shop!.location.longitude,
      );
      
      if (mounted) {
        setState(() {
          _distanceToShop = distance;
        });
      }
    } catch (e) {
      print('Error updating distance: $e');
    }
  }

  Future<void> _toggleManualStatus() async {
    if (_shop == null) return;

    try {
      final geofenceService = Provider.of<GeofenceService>(context, listen: false);
      final newStatus = _shop!.isOpen ? ShopStatus.closed : ShopStatus.open;
      
      bool success = await geofenceService.setManualStatus(newStatus);
      
      if (success) {
        setState(() {
          _shop = _shop!.copyWith(
            status: newStatus,
            isManualOverride: true,
          );
          _isManualOverride = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop status updated to ${newStatus.name.toUpperCase()}'),
            backgroundColor: AppColors.openGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${e.toString()}'),
          backgroundColor: AppColors.closedRed,
        ),
      );
    }
  }

  Future<void> _resetToLocationBased() async {
    if (_shop == null) return;

    try {
      final geofenceService = Provider.of<GeofenceService>(context, listen: false);
      await geofenceService.refreshShopData();
      
      setState(() {
        _isManualOverride = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched to location-based status'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.closedRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.ownerDashboardTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shop == null
              ? _buildNoShopView()
              : _buildShopDashboard(),
    );
  }

  Widget _buildNoShopView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.store,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            'No Shop Registered',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 10),
          
          // Subtitle
          Text(
            'Register your shop to start managing your open/closed status',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Register Button
          CustomButton(
            text: AppStrings.registerShopTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterShopScreen(),
                ),
              );
            },
            icon: Icons.add_business,
          ),
        ],
      ),
    );
  }

  Widget _buildShopDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Info Card
          _buildShopInfoCard(),
          
          const SizedBox(height: 24),
          
          // Status Card
          _buildStatusCard(),
          
          const SizedBox(height: 24),
          
          // Location Info Card
          _buildLocationCard(),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shop!.shopName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _shop!.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _shop!.phone,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusIndicator(
                isOpen: _shop!.isOpen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.shopStatus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _shop!.isOpen ? AppStrings.openStatus : AppStrings.closedStatus,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _shop!.isOpen ? AppColors.openGreen : AppColors.closedRed,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _shop!.isManualOverride 
                ? AppStrings.manualOverride 
                : AppStrings.locationBased,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Distance to Shop',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _distanceToShop != null
                ? '${_distanceToShop!.toStringAsFixed(1)} meters'
                : 'Calculating...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Shop radius: 50 meters',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Toggle Status Button
        CustomButton(
          text: _shop!.isOpen 
              ? 'Set to CLOSED' 
              : 'Set to OPEN',
          onPressed: _toggleManualStatus,
          backgroundColor: _shop!.isOpen 
              ? AppColors.closedRed 
              : AppColors.openGreen,
        ),
        
        const SizedBox(height: 12),
        
        // Reset to Location Based
        if (_isManualOverride)
          CustomOutlinedButton(
            text: 'Reset to Location Based',
            onPressed: _resetToLocationBased,
            borderColor: AppColors.primary,
            textColor: AppColors.primary,
          ),
      ],
    );
  }
}