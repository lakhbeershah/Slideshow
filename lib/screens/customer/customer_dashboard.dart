import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/routes.dart';
import 'package:opennow/widgets/shop_card.dart';
import 'package:opennow/widgets/custom_button.dart';

/// Customer dashboard for discovering and viewing nearby shops
/// Shows open shops, search functionality, and map view
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  late final FirestoreService _firestoreService;
  late final LocationService _locationService;
  late TabController _tabController;

  UserModel? _currentUser;
  List<ShopModel> _allShops = [];
  List<ShopModel> _nearbyShops = [];
  List<ShopModel> _openShops = [];
  LocationModel? _currentLocation;
  bool _isLoading = true;
  bool _showOnlyOpen = false;
  String _selectedCategory = 'All';

  // Filter options
  final List<String> _categoryFilters = ['All', ...AppStrings.shopCategories];

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _locationService = Provider.of<LocationService>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    _initializeDashboard();
  }

  /// Initialize dashboard data
  Future<void> _initializeDashboard() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.currentUser;

    await Future.wait([
      _getCurrentLocation(),
      _loadShops(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentLocationWithFallback();
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  /// Load shops from Firestore with real-time updates
  Future<void> _loadShops() async {
    try {
      // Listen to real-time shop updates
      _firestoreService.getShopsStream().listen((shops) {
        setState(() {
          _allShops = shops;
          _filterShops();
        });
      });
    } catch (e) {
      debugPrint('Error loading shops: $e');
      _showErrorSnackBar('Failed to load shops');
    }
  }

  /// Filter shops based on current filters
  void _filterShops() {
    List<ShopModel> filteredShops = _allShops;

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredShops = filteredShops
          .where((shop) => shop.category == _selectedCategory)
          .toList();
    }

    // Filter by open status
    if (_showOnlyOpen) {
      filteredShops = filteredShops
          .where((shop) => shop.status == ShopStatus.open)
          .toList();
    }

    // Calculate distances and sort by proximity
    if (_currentLocation != null) {
      for (var shop in filteredShops) {
        // In a real app, you'd calculate this more efficiently
        // For now, we'll just simulate distance calculation
      }
      
      // Get nearby shops (within 10km)
      _nearbyShops = filteredShops.take(20).toList();
    } else {
      _nearbyShops = filteredShops.take(20).toList();
    }

    // Get open shops
    _openShops = filteredShops
        .where((shop) => shop.status == ShopStatus.open)
        .take(10)
        .toList();
  }

  /// Navigate to map view
  void _navigateToMapView() {
    AppRoutes.pushNamed(context, AppRoutes.mapView);
  }

  /// Navigate to search screen
  void _navigateToSearch() {
    AppRoutes.pushNamed(context, AppRoutes.shopSearch);
  }

  /// Navigate to profile
  void _navigateToProfile() {
    AppRoutes.pushNamed(context, AppRoutes.profile);
  }

  /// Sign out user
  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (mounted) {
      AppRoutes.pushNamedAndClearStack(context, AppRoutes.login);
    }
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

  /// Calculate distance to shop
  Future<double?> _calculateDistance(ShopModel shop) async {
    if (_currentLocation == null) return null;
    
    return _locationService.calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      shop.location.latitude,
      shop.location.longitude,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Discover Shops',
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToSearch,
            icon: const Icon(Icons.search),
          ),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Nearby'),
            Tab(text: 'Open Now'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters section
                _buildFiltersSection(),
                
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNearbyTab(),
                      _buildOpenNowTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToMapView,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.map, color: Colors.white),
      ),
    );
  }

  /// Build filters section
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.grey, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Category filter
          Row(
            children: [
              Text(
                'Category: ',
                style: AppStyles.subtitle2,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryFilters.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppStyles.paddingS),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _filterShops();
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppStyles.paddingS),
          
          // Open only toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.openShopsOnly,
                  style: AppStyles.subtitle2,
                ),
              ),
              Switch(
                value: _showOnlyOpen,
                onChanged: (value) {
                  setState(() {
                    _showOnlyOpen = value;
                    _filterShops();
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build nearby shops tab
  Widget _buildNearbyTab() {
    if (_nearbyShops.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_off,
        title: 'No nearby shops',
        message: 'Try adjusting your filters or check back later',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShops,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppStyles.paddingM),
        itemCount: _nearbyShops.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppStyles.paddingM),
        itemBuilder: (context, index) {
          final shop = _nearbyShops[index];
          return FutureBuilder<double?>(
            future: _calculateDistance(shop),
            builder: (context, snapshot) {
              return ShopCard(
                shop: shop,
                distance: snapshot.data,
                onTap: () => _showShopDetails(shop),
              );
            },
          );
        },
      ),
    );
  }

  /// Build open now tab
  Widget _buildOpenNowTab() {
    if (_openShops.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        title: 'No open shops',
        message: 'No shops are currently open nearby',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShops,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppStyles.paddingM),
        itemCount: _openShops.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppStyles.paddingM),
        itemBuilder: (context, index) {
          final shop = _openShops[index];
          return FutureBuilder<double?>(
            future: _calculateDistance(shop),
            builder: (context, snapshot) {
              return ShopCard(
                shop: shop,
                distance: snapshot.data,
                onTap: () => _showShopDetails(shop),
              );
            },
          );
        },
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppStyles.paddingM),
            Text(
              title,
              style: AppStyles.subtitle1.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppStyles.paddingS),
            Text(
              message,
              style: AppStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.paddingL),
            CustomButton(
              onPressed: _loadShops,
              text: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  /// Show shop details bottom sheet
  void _showShopDetails(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyles.radiusL),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppStyles.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppStyles.paddingL),
                
                // Shop details
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShopCard(shop: shop),
                        
                        const SizedBox(height: AppStyles.paddingL),
                        
                        // Additional actions
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  // TODO: Implement call functionality
                                },
                                text: 'Call',
                                icon: const Icon(Icons.phone),
                              ),
                            ),
                            const SizedBox(width: AppStyles.paddingM),
                            Expanded(
                              child: CustomButton.secondary(
                                onPressed: () {
                                  // TODO: Implement directions functionality
                                },
                                text: 'Directions',
                                icon: const Icon(Icons.directions),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}