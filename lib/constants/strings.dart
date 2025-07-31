class AppStrings {
  // App Info
  static const String appName = "OpenNow";
  static const String appTagline = "Find shops that are open now";
  
  // Authentication
  static const String loginTitle = "Welcome to OpenNow";
  static const String loginSubtitle = "Enter your phone number to continue";
  static const String phoneNumberHint = "Phone Number";
  static const String sendOtpButton = "Send OTP";
  static const String verifyOtpTitle = "Verify OTP";
  static const String verifyOtpSubtitle = "Enter the 6-digit code sent to your phone";
  static const String otpHint = "Enter OTP";
  static const String verifyButton = "Verify";
  static const String resendOtp = "Resend OTP";
  
  // Role Selection
  static const String selectRoleTitle = "Choose your role";
  static const String shopOwner = "Shop Owner";
  static const String customer = "Customer";
  static const String shopOwnerDesc = "Manage your shop's open/closed status";
  static const String customerDesc = "Find shops that are open now";
  
  // Shop Owner
  static const String ownerDashboardTitle = "My Shop";
  static const String registerShopTitle = "Register Your Shop";
  static const String shopNameHint = "Shop Name";
  static const String shopPhoneHint = "Shop Phone";
  static const String shopCategoryHint = "Category";
  static const String selectLocation = "Select Location";
  static const String registerButton = "Register Shop";
  static const String shopStatus = "Shop Status";
  static const String openStatus = "OPEN";
  static const String closedStatus = "CLOSED";
  static const String manualOverride = "Manual Override";
  static const String locationBased = "Location Based";
  
  // Customer
  static const String customerDashboardTitle = "Find Shops";
  static const String searchHint = "Search shops by name or phone";
  static const String mapView = "Map View";
  static const String listView = "List View";
  static const String openNowFilter = "Open Now Only";
  static const String noShopsFound = "No shops found";
  static const String shopDetails = "Shop Details";
  
  // Common
  static const String loading = "Loading...";
  static const String error = "Error";
  static const String success = "Success";
  static const String cancel = "Cancel";
  static const String save = "Save";
  static const String edit = "Edit";
  static const String delete = "Delete";
  static const String logout = "Logout";
  static const String profile = "Profile";
  static const String settings = "Settings";
  
  // Categories
  static const List<String> shopCategories = [
    "Restaurant",
    "Cafe",
    "Retail",
    "Grocery",
    "Pharmacy",
    "Bank",
    "Salon",
    "Gym",
    "Other"
  ];
  
  // Error Messages
  static const String networkError = "Network error. Please check your connection.";
  static const String invalidPhone = "Please enter a valid phone number";
  static const String invalidOtp = "Please enter a valid 6-digit OTP";
  static const String locationPermissionDenied = "Location permission is required for this app";
  static const String locationServiceDisabled = "Please enable location services";
  
  // Success Messages
  static const String otpSent = "OTP sent successfully";
  static const String loginSuccess = "Login successful";
  static const String shopRegistered = "Shop registered successfully";
  static const String statusUpdated = "Status updated successfully";
}