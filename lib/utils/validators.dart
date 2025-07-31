class Validators {
  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid phone number (at least 10 digits)
    if (cleanPhone.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only digits';
    }
    
    return null;
  }

  // Validate shop name
  static String? validateShopName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shop name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Shop name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Shop name must be less than 50 characters';
    }
    
    return null;
  }

  // Validate shop phone
  static String? validateShopPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shop phone number is required';
    }
    
    // Remove all non-digit characters
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid phone number (at least 10 digits)
    if (cleanPhone.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Validate category
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }
    
    return null;
  }

  // Validate search query
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Search query is required';
    }
    
    if (value.trim().length < 2) {
      return 'Search query must be at least 2 characters';
    }
    
    return null;
  }

  // Validate email (for future use)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Validate password (for future use)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }
    
    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    return null;
  }

  // Format phone number for display
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format based on length
    if (cleanPhone.length == 10) {
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return '+1 (${cleanPhone.substring(1, 4)}) ${cleanPhone.substring(4, 7)}-${cleanPhone.substring(7)}';
    } else {
      return phone; // Return original if can't format
    }
  }

  // Clean phone number (remove formatting)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Check if string is numeric
  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^\d+$').hasMatch(value);
  }

  // Check if string is alphanumeric
  static bool isAlphanumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }

  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  // Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }
}