# OpenNow - Shop Status Tracker

A cross-platform Flutter app that allows shop owners to automatically update their open/closed status based on location, and helps customers find open shops nearby in real-time.

## Features

### 🏪 For Shop Owners
- **Phone OTP Authentication** - Secure login using Firebase Auth
- **Shop Registration** - Register shops with location, category, and contact info
- **Automatic Status Updates** - GPS-based geofencing automatically opens/closes shop when owner arrives/leaves
- **Manual Override** - Toggle shop status manually when needed
- **Real-time Updates** - Status changes are instantly reflected for customers
- **Dashboard** - Manage multiple shops from one account

### 👥 For Customers
- **Discover Shops** - Find nearby shops with distance information
- **Real-time Status** - See which shops are currently open/closed
- **Map View** - Interactive Google Maps with color-coded shop markers
- **Search & Filter** - Search by name/phone and filter by category or open status
- **Shop Details** - View shop information, contact details, and distance

## Technology Stack

- **Framework**: Flutter (latest stable)
- **Backend**: Firebase (Auth, Firestore)
- **Maps**: Google Maps API
- **Location**: Geolocator, Background location tracking
- **State Management**: Provider
- **Real-time Updates**: Firestore snapshots
- **Geofencing**: WorkManager for background processing

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase setup
├── app.dart                  # Main app widget with theming
├── routes.dart               # Navigation configuration
├── constants/                # App-wide constants
│   ├── colors.dart          # Color palette
│   ├── strings.dart         # Text constants
│   └── styles.dart          # Typography and spacing
├── models/                   # Data models
│   ├── user_model.dart      # User data structure
│   └── shop_model.dart      # Shop data structure with location
├── services/                 # Business logic and API calls
│   ├── auth_service.dart    # Firebase authentication
│   ├── firestore_service.dart # Database operations
│   ├── location_service.dart # GPS and location utilities
│   └── geofence_service.dart # Automatic status updates
├── screens/                  # UI screens
│   ├── splash/              # Splash screen
│   ├── login/               # Login and OTP screens
│   ├── owner/               # Shop owner dashboard and registration
│   ├── customer/            # Customer dashboard, map, and search
│   └── profile/             # User profile and settings
├── widgets/                  # Reusable UI components
│   ├── custom_button.dart   # Styled buttons
│   ├── custom_text_field.dart # Styled input fields
│   ├── shop_card.dart       # Shop information display
│   └── status_indicator.dart # Open/closed status widget
└── utils/                    # Helper utilities
    └── validators.dart       # Form validation
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Firebase project
- Google Maps API key
- Android Studio / VS Code

### 2. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication with Phone provider
3. Create Firestore database
4. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

### 3. Google Maps Setup

1. Get API key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable Maps SDK for Android and iOS
3. Add API key to:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`

### 4. Installation

```bash
# Clone the repository
git clone <repository-url>
cd opennow

# Install dependencies
flutter pub get

# Configure Firebase (update main.dart with your Firebase options)
# Add your Google Maps API keys

# Run the app
flutter run
```

### 5. Firebase Configuration in Code

Update `lib/main.dart` with your Firebase project settings:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "your-api-key",
    authDomain: "your-project.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:android:abc123def456",
  ),
);
```

## Database Structure

### Firestore Collections

#### Users Collection
```javascript
users/{userId} {
  phoneNumber: string,
  name: string,
  role: "owner" | "customer",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### Shops Collection
```javascript
shops/{shopId} {
  ownerId: string,
  shopName: string,
  phoneNumber: string,
  category: string,
  location: {
    latitude: number,
    longitude: number
  },
  status: "open" | "closed" | "unknown",
  isManualOverride: boolean,
  createdAt: timestamp,
  updatedAt: timestamp,
  lastStatusChange: timestamp
}
```

## Key Features Implementation

### 🔐 Authentication Flow
- Phone number input with country code detection
- Firebase OTP verification
- User role selection (Owner/Customer)
- Automatic navigation based on user type

### 📍 Geofencing Logic
- 50-meter radius detection around shop location
- Background location monitoring
- Automatic status updates when owner enters/exits
- Manual override capability
- Battery-optimized tracking

### 🗺️ Maps Integration
- Real-time shop markers with status colors
- User location tracking
- Distance calculations
- Interactive shop selection
- Clustering for performance

### 🔄 Real-time Updates
- Firestore snapshot listeners
- Instant status propagation
- Live shop discovery
- Push notifications (planned)

## Permissions Required

### Android
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `INTERNET`

### iOS
- Location When In Use
- Location Always (for background tracking)
- Network access

## Future Enhancements

- [ ] Push notifications for shop status changes
- [ ] Shop photos and descriptions
- [ ] Operating hours management
- [ ] Customer reviews and ratings
- [ ] Offers and promotions
- [ ] Analytics dashboard for owners
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Social media integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions, please open an issue in the repository or contact the development team.

---

**Note**: Remember to add your actual Firebase configuration and Google Maps API keys before running the app. The placeholder values in the code need to be replaced with your project-specific credentials.