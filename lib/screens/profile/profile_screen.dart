import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opennow/constants/colors.dart';
import 'package:opennow/constants/strings.dart';
import 'package:opennow/constants/styles.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/services/geofence_service.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/routes.dart';
import 'package:opennow/widgets/custom_button.dart';

/// Profile screen for user account management and settings
/// Shows user information and provides access to app settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load current user data
  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _currentUser = authService.currentUser;
    });
  }

  /// Sign out user
  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final geofenceService = Provider.of<GeofenceService>(context, listen: false);
    
    // Stop geofencing if active
    await geofenceService.stopMonitoring();
    
    // Sign out
    await authService.signOut();
    
    if (mounted) {
      AppRoutes.pushNamedAndClearStack(context, AppRoutes.login);
    }
  }

  /// Show sign out confirmation dialog
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            child: const Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show app info dialog
  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appTagline,
              style: AppStyles.body1,
            ),
            const SizedBox(height: AppStyles.paddingM),
            const Text(
              'Version 1.0.0',
              style: AppStyles.body2,
            ),
            const SizedBox(height: AppStyles.paddingS),
            const Text(
              'Built with Flutter',
              style: AppStyles.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.profile,
          style: AppStyles.headline3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.paddingM),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),
            
            const SizedBox(height: AppStyles.paddingL),
            
            // Settings sections
            _buildAccountSection(),
            
            const SizedBox(height: AppStyles.paddingL),
            
            _buildAppSection(),
            
            const SizedBox(height: AppStyles.paddingL),
            
            // Sign out button
            _buildSignOutSection(),
          ],
        ),
      ),
    );
  }

  /// Build profile header
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentUser?.isOwner == true ? Icons.store : Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: AppStyles.paddingM),
          
          // User name
          Text(
            _currentUser?.name ?? 'User',
            style: AppStyles.headline3,
          ),
          
          const SizedBox(height: AppStyles.paddingS),
          
          // User role
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.paddingM,
              vertical: AppStyles.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            child: Text(
              _currentUser?.isOwner == true 
                  ? AppStrings.shopOwner 
                  : AppStrings.customer,
              style: AppStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: AppStyles.paddingS),
          
          // Phone number
          Text(
            _currentUser?.phoneNumber ?? '',
            style: AppStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build account section
  Widget _buildAccountSection() {
    return Container(
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppStyles.paddingM),
            child: Text(
              'Account',
              style: AppStyles.subtitle1,
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.edit_outlined,
            title: AppStrings.editProfile,
            subtitle: 'Update your personal information',
            onTap: () {
              // TODO: Implement edit profile
              _showComingSoonDialog('Edit Profile');
            },
          ),
          
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Location Permissions',
            subtitle: 'Manage location access',
            onTap: () {
              // TODO: Implement location settings
              _showComingSoonDialog('Location Settings');
            },
          ),
          
          if (_currentUser?.isOwner == true)
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Shop status and updates',
              onTap: () {
                // TODO: Implement notification settings
                _showComingSoonDialog('Notification Settings');
              },
            ),
        ],
      ),
    );
  }

  /// Build app section
  Widget _buildAppSection() {
    return Container(
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppStyles.paddingM),
            child: Text(
              'App',
              style: AppStyles.subtitle1,
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              _showComingSoonDialog('Help & Support');
            },
          ),
          
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              _showComingSoonDialog('Privacy Policy');
            },
          ),
          
          _buildMenuItem(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () {
              _showComingSoonDialog('Terms of Service');
            },
          ),
          
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: _showAppInfo,
          ),
        ],
      ),
    );
  }

  /// Build sign out section
  Widget _buildSignOutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.paddingL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        children: [
          CustomButton(
            onPressed: _showSignOutDialog,
            text: AppStrings.logout,
            backgroundColor: AppColors.error,
            icon: const Icon(Icons.logout),
          ),
          
          const SizedBox(height: AppStyles.paddingS),
          
          Text(
            'You can always sign back in',
            style: AppStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppStyles.body1,
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }

  /// Show coming soon dialog for unimplemented features
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}