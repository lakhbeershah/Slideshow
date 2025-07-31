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

/// OTP verification screen for phone number authentication
/// Handles OTP input and verification process
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  String? _phoneNumber;
  bool _isNewUser = false;
  UserRole? _selectedRole;
  String? _name;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments passed from login screen
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _phoneNumber = arguments['phoneNumber'] as String?;
      _isNewUser = arguments['isNewUser'] as bool? ?? false;
      _selectedRole = arguments['selectedRole'] as UserRole?;
      _name = arguments['name'] as String?;
    }
  }

  /// Start countdown timer for resend OTP
  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  /// Get OTP from all text controllers
  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  /// Clear all OTP fields
  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  /// Verify OTP
  Future<void> _verifyOTP() async {
    final otp = _getOTP();
    if (otp.length != 6) {
      _showErrorDialog('Please enter complete OTP');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.verifyOTP(otp);

    if (success && mounted) {
      if (_isNewUser && _selectedRole != null && _name != null) {
        // Create user profile for new users
        final profileSuccess = await authService.createUserProfile(
          name: _name!,
          role: _selectedRole!,
        );

        if (profileSuccess && mounted) {
          // Navigate to appropriate dashboard
          if (_selectedRole == UserRole.owner) {
            AppRoutes.pushNamedAndClearStack(context, AppRoutes.ownerDashboard);
          } else {
            AppRoutes.pushNamedAndClearStack(context, AppRoutes.customerDashboard);
          }
        } else if (mounted) {
          _showErrorDialog(authService.errorMessage ?? AppStrings.somethingWentWrong);
        }
      } else {
        // Existing user - check role and navigate
        final user = authService.currentUser;
        if (user != null) {
          if (user.isOwner) {
            AppRoutes.pushNamedAndClearStack(context, AppRoutes.ownerDashboard);
          } else {
            AppRoutes.pushNamedAndClearStack(context, AppRoutes.customerDashboard);
          }
        } else {
          // User needs to complete profile setup
          AppRoutes.pushReplacement(context, AppRoutes.login);
        }
      }
    } else if (mounted) {
      _showErrorDialog(authService.errorMessage ?? AppStrings.invalidOtp);
      _clearOTP();
    }
  }

  /// Resend OTP
  Future<void> _resendOTP() async {
    if (!_canResend || _phoneNumber == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.sendOTP(_phoneNumber!);

    if (success) {
      _startResendCountdown();
      _clearOTP();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else if (mounted) {
      _showErrorDialog(authService.errorMessage ?? 'Failed to resend OTP');
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

  /// Handle OTP input
  void _onOTPChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, verify OTP
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.paddingL),
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
                    Icons.sms_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppStyles.paddingXL),

              // Title
              const Text(
                AppStrings.enterOtp,
                style: AppStyles.headline2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppStyles.paddingS),

              // Subtitle
              Text(
                '${AppStrings.otpSent}\n${_phoneNumber ?? ''}',
                style: AppStyles.subtitle2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppStyles.paddingXL),

              // OTP Input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          borderSide: const BorderSide(color: AppColors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          borderSide: const BorderSide(color: AppColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      onChanged: (value) => _onOTPChanged(value, index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppStyles.paddingXL),

              // Verify button
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return CustomButton(
                    onPressed: _verifyOTP,
                    text: AppStrings.verifyOtp,
                    isLoading: authService.isLoading,
                  );
                },
              ),

              const SizedBox(height: AppStyles.paddingL),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive OTP? ",
                    style: AppStyles.body2,
                  ),
                  if (_canResend)
                    GestureDetector(
                      onTap: _resendOTP,
                      child: const Text(
                        AppStrings.resendOtp,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend in $_resendCountdown s',
                      style: AppStyles.body2.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),

              // Error message
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (authService.errorMessage != null) {
                    return Container(
                      margin: const EdgeInsets.only(top: AppStyles.paddingL),
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
    );
  }
}