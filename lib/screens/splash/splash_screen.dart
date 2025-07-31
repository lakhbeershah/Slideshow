import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/routes.dart';

/// Splash screen that handles initial app loading and authentication check
/// Shows app logo and determines initial navigation destination
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthenticationStatus();
  }

  /// Initialize animations for the splash screen
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  /// Check authentication status and navigate accordingly
  Future<void> _checkAuthenticationStatus() async {
    // Wait for minimum splash duration for better UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      if (authService.isAuthenticated) {
        // User is authenticated, check user role and navigate to appropriate dashboard
        final user = authService.currentUser!;
        if (user.isOwner) {
          _navigateToOwnerDashboard();
        } else {
          _navigateToCustomerDashboard();
        }
      } else if (authService.needsProfileSetup) {
        // User is signed in but needs to complete profile setup
        _navigateToLogin();
      } else {
        // User is not authenticated, go to login
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      // On error, navigate to login as fallback
      _navigateToLogin();
    }
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    AppRoutes.pushNamedAndClearStack(context, AppRoutes.login);
  }

  /// Navigate to owner dashboard
  void _navigateToOwnerDashboard() {
    AppRoutes.pushNamedAndClearStack(context, AppRoutes.ownerDashboard);
  }

  /// Navigate to customer dashboard
  void _navigateToCustomerDashboard() {
    AppRoutes.pushNamedAndClearStack(context, AppRoutes.customerDashboard);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated app logo/icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppStyles.paddingXL),

              // App name
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppStyles.paddingS),

              // App tagline
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      AppStrings.appTagline,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppStyles.paddingXL * 2),

              // Loading indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}