# MediScan - AI-Powered Medicine Delivery App 💊

A Flutter-based mobile application that revolutionizes medicine ordering through AI-powered prescription scanning and seamless e-commerce functionality.

## 🌟 Features

### Core Functionality
- **AI Prescription Scanner**: Automatically scan and extract medicine names from doctor's prescriptions using image recognition
- **Medicine Catalog**: Browse and search through a comprehensive medicine database
- **Smart Cart Management**: Add medicines manually or automatically from scanned prescriptions
- **Order Tracking**: Real-time delivery tracking with GPS integration
- **User Profiles**: Personalized user accounts with order history
- **Wishlist**: Save medicines for later purchase

### Key Highlights
- 🔍 **Intelligent Search**: Search medicines by name or description
- 📸 **Multi-Source Image Input**: Capture prescriptions via camera or upload from gallery
- 🎯 **Category Filtering**: Browse medicines by categories (Tablets, Syrups, Ointments, Drops)
- 🗺️ **Live Location Tracking**: Track delivery personnel in real-time
- 🌓 **Theme Support**: Light and dark mode options
- 📱 **Responsive UI**: Beautiful gradient-based design with smooth animations

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.8.1+ (Dart)
- **Backend**: Node.js REST API (separate repository)
- **State Management**: Provider pattern
- **HTTP Client**: http package
- **Image Processing**: image_picker
- **Maps**: flutter_map with OpenStreetMap
- **PDF Generation**: pdf package
- **Storage**: shared_preferences for local data

### Project Structure
```
medi/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── medicine.dart
│   │   ├── user.dart
│   │   ├── order.dart
│   │   └── cart_item.dart
│   ├── providers/                # State management
│   │   ├── user_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── scanner_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── order_tracking_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── wishlist_screen.dart
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── services/                 # API & business logic
│   │   ├── api_service.dart
│   │   └── receipt_service.dart
│   ├── widgets/                  # Reusable components
│   │   ├── navigation.dart
│   │   └── product_card.dart
│   ├── routes/                   # Navigation
│   │   ├── app_routes.dart
│   │   └── route_generator.dart
│   └── utils/                    # Helpers & utilities
├── assets/                       # Images & resources
├── android/                      # Android configuration
├── ios/                          # iOS configuration
└── pubspec.yaml                  # Dependencies
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Node.js backend server running

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Logeshwar13/mediScan_back.git
cd medi
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Backend URL**
Update the API base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = "YOUR_BACKEND_URL/api";
```

4. **Run the app**
```bash
flutter run
```

### Backend Setup
The backend API is required for full functionality. Clone and setup:
```bash
git clone https://github.com/Logeshwar13/mediScan_back.git
cd mediScan_back
npm install
npm start
```

## 📦 Dependencies

### Core Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  http: ^1.2.2                    # API calls
  provider: ^6.1.2                # State management
  shared_preferences: ^2.2.3      # Local storage
  image_picker: ^1.1.2            # Camera/Gallery access
  geolocator: ^9.0.2              # GPS location
  geocoding: ^2.1.1               # Address lookup
  pdf: ^3.10.7                    # Receipt generation
  path_provider: ^2.1.1           # File system access
  share_plus: ^7.2.1              # Sharing functionality
  permission_handler: ^11.0.1      # App permissions
  device_info_plus: ^9.1.0        # Device information
  url_launcher: ^6.2.1            # External links
  flutter_map: ^6.1.0             # Map integration
  latlong2: ^0.9.1                # Latitude/longitude handling

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1
```

## 🔑 Key Features Explained

### 1. Prescription Scanner
- Captures prescription images via camera or gallery
- Sends image to backend AI service for OCR processing
- Automatically extracts medicine names
- Validates medicine availability in database
- Adds detected medicines to cart with one tap

### 2. Order Management
- Create orders from cart items
- Real-time order status updates
- PDF receipt generation
- Order history tracking
- Share receipts via email/messaging

### 3. Live Tracking
- GPS-based delivery tracking
- Interactive map with delivery route
- Estimated delivery time
- Delivery person contact information
- Location update notifications

### 4. User Authentication
- Secure signup/login system
- JWT token-based authentication
- Profile management
- Address management
- Persistent login sessions

## 🎨 UI/UX Features

- **Gradient Backgrounds**: Beautiful purple-to-white gradients
- **Smooth Animations**: Page transitions and loading states
- **Auto-scrolling Banners**: Promotional carousel with offers
- **Category Icons**: Visual medicine categorization
- **Product Cards**: Rich medicine display with ratings
- **Bottom Navigation**: Easy access to main sections
- **Floating Action Button**: Quick access to scanner
- **Pull-to-Refresh**: Update medicine catalog

## 🔐 Permissions Required

### Android
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS
Update `Info.plist` with required permission descriptions.

## 📱 Screens Overview

| Screen | Description |
|--------|-------------|
| **Splash** | App loading and initialization |
| **Login/Signup** | User authentication |
| **Home** | Medicine catalog with search and categories |
| **Scanner** | Prescription scanning interface |
| **Cart** | Review and manage cart items |
| **Checkout** | Order confirmation and payment |
| **Order Tracking** | Live delivery tracking with map |
| **Profile** | User account management |
| **Wishlist** | Saved medicines for later |
| **All Products** | Full medicine catalog view |

## 🔧 Configuration

### App Icon
Place your app icon at `assets/mediscan.png` and run:
```bash
flutter pub run flutter_launcher_icons
```

### Theme Customization
Modify colors in `lib/providers/theme_provider.dart`:
```dart
// Customize primary colors
primaryColor: Colors.deepPurple,
scaffoldBackgroundColor: Colors.white,
```

## 📊 API Integration

### Authentication Endpoints
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update profile

### Medicine Endpoints
- `GET /api/medicines` - Fetch all medicines
- `GET /api/medicines/search?q=query` - Search medicines
- `POST /api/scan` - Scan prescription (multipart)

### Cart Endpoints
- `GET /api/cart/:userId` - Get cart items
- `POST /api/cart/add` - Add to cart
- `PUT /api/cart/update` - Update quantity
- `DELETE /api/cart/remove` - Remove item
- `DELETE /api/cart/clear/:userId` - Clear cart

### Order Endpoints
- `GET /api/order/:userId` - Get user orders
- `POST /api/order` - Create order
- `POST /api/order/from-cart` - Create order from cart
- `GET /api/order/tracking/:orderId` - Track order

### Wishlist Endpoints
- `GET /api/wishlist/:userId` - Get wishlist
- `POST /api/wishlist/add` - Add to wishlist
- `DELETE /api/wishlist/remove` - Remove from wishlist

## 🛠️ Development

### Build for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Run Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

## 🐛 Troubleshooting

### Common Issues

**1. API Connection Failed**
- Verify backend is running
- Check `baseUrl` in `api_service.dart`
- Ensure device/emulator has internet access

**2. Image Upload Not Working**
- Grant camera and storage permissions
- Check file size limits on backend
- Verify multipart/form-data encoding

**3. Location Not Updating**
- Enable location permissions
- Check GPS is enabled on device
- Verify Google Play Services (Android)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Logeshwar** - [@Logeshwar13](https://github.com/Logeshwar13)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- OpenStreetMap for map tiles
- Unsplash for placeholder images
- Backend API contributors

## 📞 Support

For support, email your-email@example.com or open an issue on GitHub.

## 🔮 Future Enhancements

- [ ] Payment gateway integration
- [ ] Push notifications for order updates
- [ ] Medicine reminders and schedules
- [ ] Pharmacy locator
- [ ] Prescription history management
- [ ] Multi-language support
- [ ] Voice search functionality
- [ ] AR medicine information viewer
- [ ] Health tips and articles
- [ ] Loyalty program and rewards

## 📈 Version History

- **v1.0.0** (Current) - Initial release with core features
  - Prescription scanning
  - Medicine catalog
  - Cart and checkout
  - Order tracking
  - User authentication

---

**Made with ❤️ using Flutter**
