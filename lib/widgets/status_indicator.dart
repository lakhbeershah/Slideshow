import 'package:flutter/material.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/models/shop_model.dart';

/// Status indicator widget that shows shop open/closed status
/// Includes visual indicators for manual override mode
class StatusIndicator extends StatelessWidget {
  final ShopStatus status;
  final bool isManualOverride;
  final bool isCompact;

  const StatusIndicator({
    super.key,
    required this.status,
    this.isManualOverride = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppStyles.paddingS : AppStyles.paddingM,
        vertical: isCompact ? AppStyles.paddingXS : AppStyles.paddingS,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          
          SizedBox(width: isCompact ? AppStyles.paddingXS : AppStyles.paddingS),
          
          // Status text
          Text(
            _getStatusText(),
            style: (isCompact ? AppStyles.caption : AppStyles.body2).copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Manual override indicator
          if (isManualOverride && !isCompact) ...[
            const SizedBox(width: AppStyles.paddingXS),
            Icon(
              Icons.touch_app,
              size: AppStyles.iconS,
              color: _getTextColor(),
            ),
          ],
        ],
      ),
    );
  }

  /// Get status text based on current status
  String _getStatusText() {
    switch (status) {
      case ShopStatus.open:
        return 'OPEN';
      case ShopStatus.closed:
        return 'CLOSED';
      case ShopStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// Get status color for the dot indicator
  Color _getStatusColor() {
    switch (status) {
      case ShopStatus.open:
        return AppColors.shopOpen;
      case ShopStatus.closed:
        return AppColors.shopClosed;
      case ShopStatus.unknown:
        return AppColors.shopUnknown;
    }
  }

  /// Get background color for the container
  Color _getBackgroundColor() {
    final baseColor = _getStatusColor();
    return baseColor.withOpacity(0.1);
  }

  /// Get border color for the container
  Color _getBorderColor() {
    final baseColor = _getStatusColor();
    return baseColor.withOpacity(0.3);
  }

  /// Get text color
  Color _getTextColor() {
    return _getStatusColor();
  }
}

/// Factory constructors for common status indicator variations
extension StatusIndicatorExtensions on StatusIndicator {
  /// Create a compact status indicator
  static StatusIndicator compact({
    required ShopStatus status,
    bool isManualOverride = false,
  }) {
    return StatusIndicator(
      status: status,
      isManualOverride: isManualOverride,
      isCompact: true,
    );
  }

  /// Create an open status indicator
  static StatusIndicator open({bool isManualOverride = false}) {
    return StatusIndicator(
      status: ShopStatus.open,
      isManualOverride: isManualOverride,
    );
  }

  /// Create a closed status indicator
  static StatusIndicator closed({bool isManualOverride = false}) {
    return StatusIndicator(
      status: ShopStatus.closed,
      isManualOverride: isManualOverride,
    );
  }
}