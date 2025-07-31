import 'package:flutter/material.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/styles.dart';

/// Custom button widget with consistent styling and loading state
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final ButtonStyle? style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Widget? icon;
  final bool isSecondary;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.style,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isSecondary = false,
    this.width,
    this.height,
  });

  /// Factory constructor for secondary button style
  factory CustomButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    Widget? icon,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      icon: icon,
      isSecondary: true,
      width: width,
      height: height,
    );
  }

  /// Factory constructor for icon button
  factory CustomButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    required Widget icon,
    bool isLoading = false,
    bool isSecondary = false,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      icon: icon,
      isSecondary: isSecondary,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _getButtonStyle();
    final content = _buildButtonContent();

    Widget button;

    if (icon != null) {
      // Icon button
      if (isSecondary) {
        button = OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: effectiveStyle,
          icon: icon!,
          label: content,
        );
      } else {
        button = ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: effectiveStyle,
          icon: icon!,
          label: content,
        );
      }
    } else {
      // Regular button
      if (isSecondary) {
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: effectiveStyle,
          child: content,
        );
      } else {
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: effectiveStyle,
          child: content,
        );
      }
    }

    // Apply width and height constraints if specified
    if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }

  /// Build button content with loading state
  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSecondary ? AppColors.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppStyles.paddingS),
          Text(
            text,
            style: AppStyles.button.copyWith(
              color: isSecondary ? AppColors.primary : Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppStyles.button.copyWith(
        color: isSecondary ? AppColors.primary : (foregroundColor ?? Colors.white),
      ),
    );
  }

  /// Get effective button style
  ButtonStyle _getButtonStyle() {
    if (style != null) return style!;

    final effectiveBackgroundColor = backgroundColor ?? 
        (isSecondary ? Colors.transparent : AppColors.primary);
    
    final effectiveForegroundColor = foregroundColor ?? 
        (isSecondary ? AppColors.primary : Colors.white);

    final effectivePadding = padding ?? 
        const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingL,
          vertical: AppStyles.paddingM,
        );

    final effectiveBorderRadius = borderRadius ?? AppStyles.radiusM;

    if (isSecondary) {
      return OutlinedButton.styleFrom(
        foregroundColor: effectiveForegroundColor,
        backgroundColor: effectiveBackgroundColor,
        padding: effectivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        side: BorderSide(color: AppColors.primary),
        elevation: 0,
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
        padding: effectivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        elevation: AppStyles.elevationS,
        disabledBackgroundColor: AppColors.grey,
        disabledForegroundColor: Colors.white,
      );
    }
  }
}