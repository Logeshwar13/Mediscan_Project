import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/signup_page.dart';
import '../screens/verification_page.dart';
// Import your other pages here
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import 'app_routes.dart';
import '../widgets/navigation.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
        
      case AppRoutes.signup:
        return MaterialPageRoute(
          builder: (_) => const SignupPage(),
          settings: settings,
        );
        
      case AppRoutes.verification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VerificationPage(
            email: args?['email'] ?? '',
            userId: args?['userId'] ?? '',
          ),
          settings: settings,
        );
      
      // Main App Routes
      // case AppRoutes.home:
      //   return MaterialPageRoute(
      //     builder: (_) => const HomeScreen(),
      //     // Scaffold(
      //     //   body: Center(
      //     //     child: Text('Home Page - Implement your home page here'),
      //     //   ),
      //     // ),
      //     settings: settings,
      //   );
      case AppRoutes.home:
      return MaterialPageRoute(
      builder: (_) => const NavigationWrapper(
        child: HomeScreen(),
       initialIndex: 0,
    ),
    settings: settings,
  );
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          // Scaffold(
          //   body: Center(
          //     child: Text('Profile Page - Implement your profile page here'),
          //   ),
          // ),
          settings: settings,
        );
      
      // Default/Splash Route
      case AppRoutes.splash:
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
          settings: settings,
        );
    }
  }
}

// Splash Screen to check authentication
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add delay for splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Check if user is logged in using your UserProvider
    // For now, navigate to login
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 120,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'MediScan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Health, Our Priority',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// 404 Page
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}