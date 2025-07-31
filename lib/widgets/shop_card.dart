import 'package:flutter/material.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/models/shop_model.dart';
import 'package:opennow/widgets/status_indicator.dart';
import 'package:opennow/widgets/custom_button.dart';

/// Shop card widget for displaying shop information
/// Can be used in both owner and customer views with different interactions
class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final bool isOwnerView;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;
  final VoidCallback? onClearOverride;
  final double? distance;

  const ShopCard({
    super.key,
    required this.shop,
    this.isOwnerView = false,
    this.onTap,
    this.onStatusToggle,
    this.onClearOverride,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppStyles.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with shop name and status
              _buildHeader(),
              
              const SizedBox(height: AppStyles.paddingS),
              
              // Shop details
              _buildShopDetails(),
              
              // Owner controls or customer distance
              if (isOwnerView) ...[
                const SizedBox(height: AppStyles.paddingM),
                _buildOwnerControls(context),
              ] else if (distance != null) ...[
                const SizedBox(height: AppStyles.paddingS),
                _buildDistanceInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with shop name and status
  Widget _buildHeader() {
    return Row(
      children: [
        // Shop icon
        Container(
          padding: const EdgeInsets.all(AppStyles.paddingS),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
          child: Icon(
            _getCategoryIcon(),
            color: _getCategoryColor(),
            size: AppStyles.iconM,
          ),
        ),
        
        const SizedBox(width: AppStyles.paddingM),
        
        // Shop name and category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.shopName,
                style: AppStyles.subtitle1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppStyles.paddingXS),
              Text(
                shop.category,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Status indicator
        StatusIndicator(
          status: shop.status,
          isManualOverride: shop.isManualOverride,
        ),
      ],
    );
  }

  /// Build shop details section
  Widget _buildShopDetails() {
    return Column(
      children: [
        // Phone number
        _buildDetailRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: shop.phoneNumber,
        ),
        
        const SizedBox(height: AppStyles.paddingXS),
        
        // Last status change
        if (shop.lastStatusChange != null)
          _buildDetailRow(
            icon: Icons.schedule_outlined,
            label: 'Last updated',
            value: _formatDateTime(shop.lastStatusChange!),
          ),
      ],
    );
  }

  /// Build detail row
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppStyles.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppStyles.paddingS),
        Text(
          '$label: ',
          style: AppStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build owner controls section
  Widget _buildOwnerControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manual override indicator
        if (shop.isManualOverride)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.paddingS,
              vertical: AppStyles.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusS),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  size: AppStyles.iconS,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppStyles.paddingXS),
                Text(
                  'Manual Override Active',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        
        if (shop.isManualOverride)
          const SizedBox(height: AppStyles.paddingS),
        
        // Control buttons
        Row(
          children: [
            // Status toggle button
            Expanded(
              child: CustomButton(
                onPressed: onStatusToggle,
                text: shop.isOpen ? 'Mark Closed' : 'Mark Open',
                backgroundColor: shop.isOpen ? AppColors.error : AppColors.success,
                height: 36,
              ),
            ),
            
            // Clear override button (if manual override is active)
            if (shop.isManualOverride && onClearOverride != null) ...[
              const SizedBox(width: AppStyles.paddingS),
              CustomButton.secondary(
                onPressed: onClearOverride,
                text: 'Auto Mode',
                width: 80,
                height: 36,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build distance information for customer view
  Widget _buildDistanceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingS,
        vertical: AppStyles.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: AppStyles.iconS,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppStyles.paddingXS),
          Text(
            _formatDistance(distance!),
            style: AppStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get category icon based on shop category
  IconData _getCategoryIcon() {
    switch (shop.category.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'grocery store':
        return Icons.local_grocery_store;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'clothing store':
        return Icons.local_mall;
      case 'electronics':
        return Icons.electrical_services;
      case 'bookstore':
        return Icons.menu_book;
      case 'bakery':
        return Icons.bakery_dining;
      case 'beauty salon':
        return Icons.content_cut;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.store;
    }
  }

  /// Get category color based on shop category
  Color _getCategoryColor() {
    switch (shop.category.toLowerCase()) {
      case 'restaurant':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'grocery store':
        return Colors.green;
      case 'pharmacy':
        return Colors.red;
      case 'clothing store':
        return Colors.purple;
      case 'electronics':
        return Colors.blue;
      case 'bookstore':
        return Colors.indigo;
      case 'bakery':
        return Colors.amber;
      case 'beauty salon':
        return Colors.pink;
      case 'gym':
        return Colors.deepOrange;
      default:
        return AppColors.primary;
    }
  }

  /// Format distance for display
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km away';
    }
  }

  /// Format date/time for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}