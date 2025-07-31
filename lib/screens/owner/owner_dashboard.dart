import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/geofence_service.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/routes.dart';
import 'package:opennow/widgets/custom_button.dart';
import 'package:opennow/widgets/shop_card.dart';
import 'package:opennow/widgets/status_indicator.dart';

/// Owner dashboard displaying shop management features and status controls
/// Allows owners to register shops, toggle status, and monitor geofencing
class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  late final FirestoreService _firestoreService;
  late final GeofenceService _geofenceService;
  UserModel? _currentUser;
  List<ShopModel> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _geofenceService = Provider.of<GeofenceService>(context, listen: false);
    _initializeDashboard();
  }

  /// Initialize dashboard data and geofencing
  Future<void> _initializeDashboard() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.currentUser;

    if (_currentUser != null) {
      await _loadShops();
      await _startGeofencing();
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Load user's shops from Firestore
  Future<void> _loadShops() async {
    if (_currentUser == null) return;

    try {
      final shops = await _firestoreService.getShopsByOwner(_currentUser!.id);
      setState(() {
        _shops = shops;
      });
    } catch (e) {
      debugPrint('Error loading shops: $e');
      _showErrorSnackBar('Failed to load shops');
    }
  }

  /// Start geofencing for automatic status updates
  Future<void> _startGeofencing() async {
    if (_currentUser == null) return;

    final hasPermissions = await _geofenceService.checkPermissions();
    if (!hasPermissions) {
      final granted = await _geofenceService.requestPermissions();
      if (!granted) {
        _showPermissionDialog();
        return;
      }
    }

    final success = await _geofenceService.startMonitoring(_currentUser!);
    if (!success) {
      debugPrint('Failed to start geofencing');
    }
  }

  /// Navigate to shop registration
  void _navigateToRegisterShop() {
    AppRoutes.pushNamed(context, AppRoutes.registerShop);
  }

  /// Navigate to profile
  void _navigateToProfile() {
    AppRoutes.pushNamed(context, AppRoutes.profile);
  }

  /// Toggle shop status manually
  Future<void> _toggleShopStatus(ShopModel shop) async {
    try {
      final success = await _geofenceService.toggleShopStatus(shop.id);
      if (success) {
        _showSuccessSnackBar('Shop status updated');
        await _loadShops(); // Refresh shop data
      } else {
        _showErrorSnackBar('Failed to update shop status');
      }
    } catch (e) {
      debugPrint('Error toggling shop status: $e');
      _showErrorSnackBar('Failed to update shop status');
    }
  }

  /// Clear manual override and return to auto mode
  Future<void> _clearManualOverride(ShopModel shop) async {
    try {
      final success = await _geofenceService.clearManualOverride(shop.id);
      if (success) {
        _showSuccessSnackBar('Returned to automatic mode');
        await _loadShops();
      } else {
        _showErrorSnackBar('Failed to clear manual override');
      }
    } catch (e) {
      debugPrint('Error clearing manual override: $e');
      _showErrorSnackBar('Failed to clear manual override');
    }
  }

  /// Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.locationPermission),
        content: const Text(AppStrings.locationPermissionDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _geofenceService.requestPermissions();
            },
            child: const Text(AppStrings.grantPermission),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Sign out user
  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await _geofenceService.stopMonitoring();
    await authService.signOut();
    if (mounted) {
      AppRoutes.pushNamedAndClearStack(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Shops',
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToProfile,
            icon: const Icon(Icons.person_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: AppStyles.paddingS),
                    Text(AppStrings.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShops,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppStyles.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),
                    
                    const SizedBox(height: AppStyles.paddingL),
                    
                    // Geofencing status
                    _buildGeofencingStatus(),
                    
                    const SizedBox(height: AppStyles.paddingL),
                    
                    // Shops section
                    _buildShopsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegisterShop,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Shop'),
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: AppStyles.body1.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppStyles.paddingXS),
          Text(
            _currentUser?.name ?? 'Shop Owner',
            style: AppStyles.headline3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppStyles.paddingS),
          Text(
            _shops.isEmpty
                ? 'Register your first shop to get started'
                : 'You have ${_shops.length} shop${_shops.length == 1 ? '' : 's'}',
            style: AppStyles.body2.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Build geofencing status section
  Widget _buildGeofencingStatus() {
    return Consumer<GeofenceService>(
      builder: (context, geofenceService, child) {
        return Container(
          padding: const EdgeInsets.all(AppStyles.paddingM),
          decoration: AppStyles.cardDecoration,
          child: Row(
            children: [
              Icon(
                geofenceService.isMonitoring
                    ? Icons.location_on
                    : Icons.location_off,
                color: geofenceService.isMonitoring
                    ? AppColors.success
                    : AppColors.error,
                size: AppStyles.iconL,
              ),
              const SizedBox(width: AppStyles.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Status Updates',
                      style: AppStyles.subtitle1,
                    ),
                    const SizedBox(height: AppStyles.paddingXS),
                    Text(
                      geofenceService.isMonitoring
                          ? 'Active - Your shops will automatically update when you arrive/leave'
                          : 'Inactive - Enable location permissions for automatic updates',
                      style: AppStyles.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build shops section
  Widget _buildShopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Shops',
              style: AppStyles.headline3,
            ),
            if (_shops.isNotEmpty)
              TextButton.icon(
                onPressed: _navigateToRegisterShop,
                icon: const Icon(Icons.add, size: AppStyles.iconS),
                label: const Text('Add Shop'),
              ),
          ],
        ),
        
        const SizedBox(height: AppStyles.paddingM),
        
        if (_shops.isEmpty)
          _buildEmptyState()
        else
          _buildShopsList(),
      ],
    );
  }

  /// Build empty state when no shops
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.paddingXL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppStyles.paddingM),
          Text(
            'No shops registered',
            style: AppStyles.subtitle1.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppStyles.paddingS),
          Text(
            'Register your first shop to start managing your business status',
            style: AppStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.paddingL),
          CustomButton(
            onPressed: _navigateToRegisterShop,
            text: AppStrings.registerShop,
          ),
        ],
      ),
    );
  }

  /// Build shops list
  Widget _buildShopsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _shops.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppStyles.paddingM),
      itemBuilder: (context, index) {
        final shop = _shops[index];
        return ShopCard(
          shop: shop,
          isOwnerView: true,
          onStatusToggle: () => _toggleShopStatus(shop),
          onClearOverride: shop.isManualOverride 
              ? () => _clearManualOverride(shop)
              : null,
        );
      },
    );
  }
}