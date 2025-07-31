# OpenNow - Real-time Shop Status App

A Flutter app that allows shop owners to show real-time open/closed status based on their location, and customers to find shops that are open now.

## 🚀 Features

### For Shop Owners
- **Phone OTP Authentication**: Secure login with Firebase phone authentication
- **Shop Registration**: Register your shop with name, phone, category, and location
- **Automatic Status Management**: Shop automatically switches to OPEN when owner is within 50m radius
- **Manual Override**: Manual toggle for special circumstances (e.g., "Closed for lunch")
- **Real-time Updates**: Status updates in real-time using Firestore
- **Location Tracking**: Background location tracking for automatic status changes

### For Customers
- **Shop Discovery**: Find shops by name, phone, or category
- **Real-time Status**: See which shops are currently open or closed
- **Map View**: View shops on an interactive map with color-coded markers
- **List View**: Browse shops in a clean list format
- **Search & Filter**: Search shops and filter for "Open Now" only
- **Shop Details**: View detailed information about each shop

## 🛠️ Technical Stack

- **Framework**: Flutter (latest stable version)
- **Backend**: Firebase (Authentication, Firestore)
- **Maps**: Google Maps API
- **Location**: Geolocator package
- **State Management**: Provider
- **UI**: Material Design 3

## 📱 Screenshots

### Authentication Flow
- Splash Screen with animated logo
- Phone number input with OTP verification
- Role selection (Shop Owner vs Customer)

### Shop Owner Dashboard
- Shop status display with manual override
- Distance to shop location
- Real-time status updates
- Shop registration with map location picker

### Customer Dashboard
- Shop search with filters
- List and map view options
- Shop details with contact information
- Real-time status indicators

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK**: Install Flutter (latest stable version)
2. **Firebase Project**: Create a Firebase project
3. **Google Maps API Key**: Get a Google Maps API key

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd opennow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication with Phone provider
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Google Maps API Key**
   - Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Replace the placeholder in `lib/main.dart`:
     ```dart
     apiKey: "YOUR_GOOGLE_MAPS_API_KEY",
     ```

5. **Firebase Configuration**
   - Replace the Firebase configuration in `lib/main.dart`:
     ```dart
     apiKey: "YOUR_FIREBASE_API_KEY",
     appId: "YOUR_FIREBASE_APP_ID",
     messagingSenderId: "YOUR_SENDER_ID",
     projectId: "YOUR_PROJECT_ID",
     ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── app.dart                  # App configuration and theme
├── routes.dart               # Navigation routes
├── constants/
│   ├── colors.dart          # App color scheme
│   └── strings.dart         # App text strings
├── models/
│   ├── user_model.dart      # User data model
│   └── shop_model.dart      # Shop data model
├── services/
│   ├── auth_service.dart    # Firebase authentication
│   ├── firestore_service.dart # Firestore database operations
│   ├── location_service.dart # GPS location handling
│   └── geofence_service.dart # Geofencing logic
├── screens/
│   ├── splash_screen.dart   # App splash screen
│   ├── login/
│   │   ├── login_screen.dart
│   │   └── otp_screen.dart
│   ├── owner/
│   │   ├── owner_dashboard.dart
│   │   └── register_shop_screen.dart
│   ├── customer/
│   │   ├── customer_dashboard.dart
│   │   ├── map_view_screen.dart
│   │   └── shop_search_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/
│   ├── custom_button.dart   # Reusable button component
│   ├── custom_text_field.dart # Reusable text field
│   ├── shop_card.dart       # Shop display card
│   └── status_indicator.dart # Status indicator widget
└── utils/
    └── validators.dart      # Form validation utilities
```

## 🔧 Configuration

### Firebase Firestore Rules

Set up the following Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shops collection
    match /shops/{shopId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.ownerId == request.auth.uid);
    }
  }
}
```

### Android Permissions

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS Permissions

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby shops and track your location for shop owners.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby shops and track your location for shop owners.</string>
```

## 🎯 Key Features Explained

### Geofencing Logic
- Shop owners' location is tracked in the background
- When owner enters 50m radius of shop → status = OPEN
- When owner exits radius → status = CLOSED
- Manual override available for special circumstances

### Real-time Updates
- Uses Firestore streams for real-time data synchronization
- Shop status updates immediately across all devices
- No need to refresh - changes appear instantly

### Search & Filter
- Search by shop name, phone number, or category
- Filter to show only open shops
- Category-based filtering
- Distance-based sorting (future enhancement)

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🔮 Future Enhancements

- [ ] Push notifications for status changes
- [ ] Shop photos and descriptions
- [ ] Customer reviews and ratings
- [ ] Operating hours management
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Shop analytics dashboard
- [ ] Payment integration
- [ ] Chat feature between customers and shop owners

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps for location services
- The open-source community for various packages used

---

**Note**: This is a production-ready MVP. The app includes all core functionality and can be deployed immediately after adding your Firebase and Google Maps API keys.