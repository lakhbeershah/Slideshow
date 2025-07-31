import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/routes.dart';
import 'package:opennow/widgets/custom_button.dart';
import 'package:opennow/widgets/custom_text_field.dart';

/// Login screen with phone number input and user role selection
/// Handles OTP authentication and profile creation for new users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  UserRole? _selectedRole;
  bool _isNewUser = false;
  bool _showRoleSelection = false;

  @override
  void initState() {
    super.initState();
    _checkIfNewUser();
  }

  /// Check if user needs to complete profile setup
  void _checkIfNewUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.needsProfileSetup) {
      setState(() {
        _isNewUser = true;
        _showRoleSelection = true;
      });
    }
  }

  /// Send OTP to phone number
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Format phone number (add country code if not present)
    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+1$phoneNumber'; // Default to US country code
    }

    final success = await authService.sendOTP(phoneNumber);
    
    if (success && mounted) {
      // Navigate to OTP verification screen
      AppRoutes.pushNamed(context, AppRoutes.otp, arguments: {
        'phoneNumber': phoneNumber,
        'isNewUser': _isNewUser,
        'selectedRole': _selectedRole,
        'name': _nameController.text.trim(),
      });
    } else if (mounted) {
      // Show error message
      _showErrorDialog(authService.errorMessage ?? AppStrings.somethingWentWrong);
    }
  }

  /// Create user profile for new users
  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate() || _selectedRole == null) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    final success = await authService.createUserProfile(
      name: _nameController.text.trim(),
      role: _selectedRole!,
    );

    if (success && mounted) {
      // Navigate to appropriate dashboard
      if (_selectedRole == UserRole.owner) {
        AppRoutes.pushNamedAndClearStack(context, AppRoutes.ownerDashboard);
      } else {
        AppRoutes.pushNamedAndClearStack(context, AppRoutes.customerDashboard);
      }
    } else if (mounted) {
      _showErrorDialog(authService.errorMessage ?? AppStrings.somethingWentWrong);
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  /// Validate phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters for validation
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validate name
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _showRoleSelection
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _showRoleSelection = false;
                    _isNewUser = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppStyles.paddingXL),

                // App logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    ),
                    child: const Icon(
                      Icons.store_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: AppStyles.paddingXL),

                // Welcome text
                const Text(
                  AppStrings.welcome,
                  style: AppStyles.headline2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppStyles.paddingS),

                // Subtitle
                Text(
                  _showRoleSelection 
                      ? 'Complete your profile to get started'
                      : AppStrings.enterPhone,
                  style: AppStyles.subtitle2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppStyles.paddingXL),

                if (_showRoleSelection) ...[
                  // Profile setup form
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: AppStyles.paddingL),

                  // Role selection
                  const Text(
                    AppStrings.selectRole,
                    style: AppStyles.subtitle1,
                  ),

                  const SizedBox(height: AppStyles.paddingM),

                  _buildRoleCard(
                    role: UserRole.owner,
                    title: AppStrings.shopOwner,
                    description: AppStrings.shopOwnerDesc,
                    icon: Icons.store,
                  ),

                  const SizedBox(height: AppStyles.paddingM),

                  _buildRoleCard(
                    role: UserRole.customer,
                    title: AppStrings.customer,
                    description: AppStrings.customerDesc,
                    icon: Icons.shopping_bag_outlined,
                  ),

                  const SizedBox(height: AppStyles.paddingXL),

                  // Create profile button
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return CustomButton(
                        onPressed: _selectedRole != null ? _createProfile : null,
                        text: 'Complete Setup',
                        isLoading: authService.isLoading,
                      );
                    },
                  ),
                ] else ...[
                  // Phone number input
                  CustomTextField(
                    controller: _phoneController,
                    labelText: AppStrings.phoneNumber,
                    hintText: '+1 (555) 123-4567',
                    validator: _validatePhoneNumber,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\(\)\s]')),
                    ],
                    prefixIcon: Icons.phone_outlined,
                    onSubmitted: (_) => _sendOTP(),
                  ),

                  const SizedBox(height: AppStyles.paddingXL),

                  // Send OTP button
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return CustomButton(
                        onPressed: _sendOTP,
                        text: AppStrings.sendOtp,
                        isLoading: authService.isLoading,
                      );
                    },
                  ),
                ],

                // Error message
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    if (authService.errorMessage != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: AppStyles.paddingM),
                        padding: const EdgeInsets.all(AppStyles.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          authService.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build role selection card
  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingL),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.paddingM),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: AppStyles.iconL,
              ),
            ),
            
            const SizedBox(width: AppStyles.paddingM),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.subtitle1.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingXS),
                  Text(
                    description,
                    style: AppStyles.body2,
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppStyles.iconM,
              ),
          ],
        ),
      ),
    );
  }
}