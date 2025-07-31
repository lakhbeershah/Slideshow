import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/widgets/shop_card.dart';
import 'package:opennow/widgets/custom_text_field.dart';

/// Shop search screen for finding shops by name or phone number
/// Provides real-time search with filtering options
class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  late final FirestoreService _firestoreService;
  late final LocationService _locationService;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<ShopModel> _searchResults = [];
  List<ShopModel> _recentShops = [];
  LocationModel? _currentLocation;
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _locationService = Provider.of<LocationService>(context, listen: false);
    _initializeSearch();
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  /// Initialize search screen
  Future<void> _initializeSearch() async {
    await _getCurrentLocation();
    await _loadRecentShops();
  }

  /// Get current location for distance calculations
  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentLocationWithFallback();
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  /// Load recent/popular shops
  Future<void> _loadRecentShops() async {
    try {
      final shops = await _firestoreService.getAllShops(limit: 10);
      setState(() {
        _recentShops = shops;
      });
    } catch (e) {
      debugPrint('Error loading recent shops: $e');
    }
  }

  /// Perform search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });

    try {
      final results = await _firestoreService.searchShops(query.trim());
      setState(() {
        _searchResults = results;
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint('Error searching shops: $e');
      _showErrorSnackBar('Search failed. Please try again.');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _hasSearched = false;
      _searchQuery = '';
    });
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

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Show shop details
  void _showShopDetails(ShopModel shop) {
    // TODO: Implement shop details navigation or bottom sheet
    debugPrint('Show details for ${shop.shopName}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Search Shops',
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: AppStrings.searchShops,
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: _performSearch,
            ),
          ),
          
          if (_isSearching) ...[
            const SizedBox(width: AppStyles.paddingM),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    if (_hasSearched) {
      return _buildSearchResults();
    } else {
      return _buildDefaultContent();
    }
  }

  /// Build search results
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptySearchResults();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results header
        Padding(
          padding: const EdgeInsets.all(AppStyles.paddingM),
          child: Text(
            'Search Results for "$_searchQuery"',
            style: AppStyles.subtitle1,
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingM),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => 
                const SizedBox(height: AppStyles.paddingM),
            itemBuilder: (context, index) {
              final shop = _searchResults[index];
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
        ),
      ],
    );
  }

  /// Build empty search results
  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppStyles.paddingM),
            Text(
              AppStrings.noShopsFound,
              style: AppStyles.subtitle1.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppStyles.paddingS),
            Text(
              'Try searching with different keywords',
              style: AppStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build default content (when not searching)
  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          _buildSearchSuggestions(),
          
          const SizedBox(height: AppStyles.paddingL),
          
          // Recent/Popular shops
          if (_recentShops.isNotEmpty) _buildRecentShops(),
        ],
      ),
    );
  }

  /// Build search suggestions
  Widget _buildSearchSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Suggestions',
          style: AppStyles.subtitle1,
        ),
        
        const SizedBox(height: AppStyles.paddingM),
        
        Wrap(
          spacing: AppStyles.paddingS,
          runSpacing: AppStyles.paddingS,
          children: [
            _buildSuggestionChip('Coffee'),
            _buildSuggestionChip('Restaurant'),
            _buildSuggestionChip('Pharmacy'),
            _buildSuggestionChip('Grocery'),
            _buildSuggestionChip('Shopping'),
          ],
        ),
      ],
    );
  }

  /// Build suggestion chip
  Widget _buildSuggestionChip(String suggestion) {
    return ActionChip(
      label: Text(suggestion),
      onPressed: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
    );
  }

  /// Build recent shops section
  Widget _buildRecentShops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Shops',
          style: AppStyles.subtitle1,
        ),
        
        const SizedBox(height: AppStyles.paddingM),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentShops.length,
          separatorBuilder: (context, index) => 
              const SizedBox(height: AppStyles.paddingM),
          itemBuilder: (context, index) {
            final shop = _recentShops[index];
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
      ],
    );
  }
}