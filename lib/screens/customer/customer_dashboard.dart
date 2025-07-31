import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../models/shop_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_search_field.dart';
import '../../widgets/shop_card.dart';
import '../../widgets/status_indicator.dart';
import 'map_view_screen.dart';
import 'shop_search_screen.dart';
import '../profile/profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ShopModel> _shops = [];
  List<ShopModel> _filteredShops = [];
  bool _isLoading = true;
  bool _showOpenOnly = false;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    try {
      _firestoreService.getShopsStream(openOnly: _showOpenOnly).listen((shops) {
        if (mounted) {
          setState(() {
            _shops = shops;
            _filteredShops = _filterShops(shops);
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ShopModel> _filterShops(List<ShopModel> shops) {
    if (_searchController.text.isEmpty) {
      return shops;
    }
    
    final query = _searchController.text.toLowerCase();
    return shops.where((shop) {
      return shop.shopName.toLowerCase().contains(query) ||
             shop.phone.contains(query) ||
             shop.category.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredShops = _filterShops(_shops);
    });
  }

  void _toggleOpenOnly(bool? value) {
    setState(() {
      _showOpenOnly = value ?? false;
    });
    _loadShops();
  }

  void _toggleViewMode() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  void _navigateToMapView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapViewScreen(
          shops: _filteredShops,
          showOpenOnly: _showOpenOnly,
        ),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopSearchScreen(
          shops: _shops,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.customerDashboardTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: _toggleViewMode,
          ),
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
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),
          
          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMapView
                    ? _buildMapView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          CustomSearchField(
            controller: _searchController,
            hintText: AppStrings.searchHint,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filter Row
          Row(
            children: [
              // Open Now Filter
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _showOpenOnly,
                      onChanged: _toggleOpenOnly,
                      activeColor: AppColors.openGreen,
                    ),
                    Text(
                      AppStrings.openNowFilter,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Shop Count
              Text(
                '${_filteredShops.length} shops',
                style: TextStyle(
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

  Widget _buildListView() {
    if (_filteredShops.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        final shop = _filteredShops[index];
        return ShopCard(
          shop: shop,
          onTap: () => _showShopDetails(shop),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map Placeholder (in real app, this would be Google Maps)
            Container(
              height: double.infinity,
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Map View',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_filteredShops.length} shops found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Map View Button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _navigateToMapView,
                backgroundColor: AppColors.primary,
                child: const Icon(
                  Icons.map,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noShopsFound,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'No shops available in your area'
                : 'No shops match your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showShopDetails(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Header
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.shopName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shop.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(isOpen: shop.isOpen),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Shop Details
                    _buildDetailRow(Icons.phone, 'Phone', shop.phone),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.category, 'Category', shop.category),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      '${shop.location.latitude.toStringAsFixed(4)}, ${shop.location.longitude.toStringAsFixed(4)}',
                    ),
                    
                    const Spacer(),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomOutlinedButton(
                            text: 'Call',
                            onPressed: () {
                              // TODO: Implement call functionality
                            },
                            icon: Icons.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Directions',
                            onPressed: () {
                              // TODO: Implement directions functionality
                            },
                            icon: Icons.directions,
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}