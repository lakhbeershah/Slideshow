/// Application string constants
/// Centralized location for all text used in the app
class AppStrings {
  // App
  static const String appName = 'OpenNow';
  static const String appTagline = 'Find open shops near you';
  
  // Authentication
  static const String welcome = 'Welcome to OpenNow';
  static const String enterPhone = 'Enter your phone number';
  static const String phoneNumber = 'Phone Number';
  static const String sendOtp = 'Send OTP';
  static const String enterOtp = 'Enter OTP';
  static const String otpSent = 'OTP sent to your phone';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  static const String invalidOtp = 'Invalid OTP';
  static const String otpExpired = 'OTP expired';
  
  // User roles
  static const String selectRole = 'Select your role';
  static const String shopOwner = 'Shop Owner';
  static const String customer = 'Customer';
  static const String shopOwnerDesc = 'Manage your shop status';
  static const String customerDesc = 'Find open shops nearby';
  
  // Shop management
  static const String registerShop = 'Register Your Shop';
  static const String shopName = 'Shop Name';
  static const String shopCategory = 'Category';
  static const String selectLocation = 'Select Shop Location';
  static const String shopRegistered = 'Shop registered successfully';
  static const String updateShop = 'Update Shop';
  
  // Shop status
  static const String shopOpen = 'OPEN';
  static const String shopClosed = 'CLOSED';
  static const String openNow = 'Open Now';
  static const String closedNow = 'Closed Now';
  static const String manualToggle = 'Manual Toggle';
  static const String autoMode = 'Auto Mode';
  
  // Search and discovery
  static const String searchShops = 'Search shops...';
  static const String nearbyShops = 'Nearby Shops';
  static const String allShops = 'All Shops';
  static const String openShopsOnly = 'Open shops only';
  static const String noShopsFound = 'No shops found';
  static const String mapView = 'Map View';
  static const String listView = 'List View';
  
  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String logout = 'Logout';
  static const String settings = 'Settings';
  
  // Permissions
  static const String locationPermission = 'Location Permission Required';
  static const String locationPermissionDesc = 'This app needs location access to show nearby shops and track shop status';
  static const String grantPermission = 'Grant Permission';
  static const String permissionDenied = 'Permission denied';
  
  // Errors
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternetConnection = 'No internet connection';
  static const String tryAgain = 'Try Again';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  
  // Categories
  static const List<String> shopCategories = [
    'Restaurant',
    'Cafe',
    'Grocery Store',
    'Pharmacy',
    'Clothing Store',
    'Electronics',
    'Bookstore',
    'Bakery',
    'Beauty Salon',
    'Gym',
    'Other',
  ];
}