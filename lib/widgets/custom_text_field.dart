import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/styles.dart';

/// Custom text field widget with consistent styling and validation
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onEditingComplete;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool autofocus;

  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.autofocus = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    
    // Add focus listener
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppStyles.subtitle2.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppStyles.paddingS),
        ],

        // Text field
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          style: AppStyles.body1,
          decoration: _buildInputDecoration(),
        ),

        // Helper text
        if (widget.helperText != null) ...[
          const SizedBox(height: AppStyles.paddingXS),
          Text(
            widget.helperText!,
            style: AppStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: AppStyles.body1.copyWith(
        color: AppColors.textHint,
      ),
      
      // Prefix icon
      prefixIcon: widget.prefixIcon != null
          ? Icon(
              widget.prefixIcon,
              color: _isFocused ? AppColors.primary : AppColors.textHint,
              size: AppStyles.iconM,
            )
          : null,
      
      // Suffix icon (with password toggle for obscureText)
      suffixIcon: _buildSuffixIcon(),
      
      // Content padding
      contentPadding: widget.contentPadding ?? 
          const EdgeInsets.symmetric(
            horizontal: AppStyles.paddingM,
            vertical: AppStyles.paddingM,
          ),
      
      // Fill color
      filled: true,
      fillColor: widget.fillColor ?? 
          (widget.enabled ? AppColors.surface : AppColors.greyLight),
      
      // Borders
      border: _buildBorder(AppColors.grey),
      enabledBorder: _buildBorder(AppColors.grey),
      focusedBorder: _buildBorder(AppColors.primary, width: 2),
      errorBorder: _buildBorder(AppColors.error),
      focusedErrorBorder: _buildBorder(AppColors.error, width: 2),
      disabledBorder: _buildBorder(AppColors.greyLight),
      
      // Counter
      counterStyle: AppStyles.caption.copyWith(
        color: AppColors.textHint,
      ),
      
      // Error style
      errorStyle: AppStyles.caption.copyWith(
        color: AppColors.error,
      ),
      
      // Helper style
      helperStyle: AppStyles.caption.copyWith(
        color: AppColors.textHint,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      // Password toggle icon
      return IconButton(
        onPressed: _toggleObscureText,
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textHint,
          size: AppStyles.iconM,
        ),
      );
    } else if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }
    return null;
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppStyles.radiusM),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}