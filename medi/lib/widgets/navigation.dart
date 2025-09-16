// navigation.dart - Enhanced navigation with STATIC scanner button
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scanner_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF7B68EE).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'My Cart',
            index: 1,
            isActive: currentIndex == 1,
          ),
          const SizedBox(width: 65), // Space for floating action button
          _buildNavItem(
            context: context,
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: 'Wishlist',
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: 3,
            isActive: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        onTap(index);
        
        if (!isActive) {
          Widget targetScreen;
          switch (index) {
            case 0:
              targetScreen = const NavigationWrapper(
                child: HomeScreen(),
                initialIndex: 0,
              );
              break;
            case 1:
              targetScreen = const NavigationWrapper(
                child: CartScreen(),
                initialIndex: 1,
              );
              break;
            case 2:
              targetScreen = const NavigationWrapper(
                child: WishlistScreen(),
                initialIndex: 2,
              );
              break;
            case 3:
              targetScreen = const NavigationWrapper(
                child: ProfileScreen(),
                initialIndex: 3,
              );
              break;
            default:
              targetScreen = const NavigationWrapper(
                child: HomeScreen(),
                initialIndex: 0,
              );
          }

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? const Color(0xFF7B68EE) : Colors.grey,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF7B68EE) : Colors.grey,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomFloatingActionButton extends StatefulWidget {
  final VoidCallback? onTap;

  const CustomFloatingActionButton({
    super.key,
    this.onTap,
  });

  @override
  State<CustomFloatingActionButton> createState() => _CustomFloatingActionButtonState();
}

class _CustomFloatingActionButtonState extends State<CustomFloatingActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // Moved down from 35 to 20
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
          // Execute the tap action
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScannerScreen(),
              ),
            );
          }
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color.fromARGB(255, 154, 0, 0).withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0,5),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.qr_code_scanner,
                key: ValueKey(_isPressed),
                color: _isPressed ? const Color(0xFF7B68EE) : const Color.fromARGB(255, 154, 0, 0),
                size: _isPressed ? 32 : 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Navigation Wrapper Widget - FIXED FOR STATIC SCANNER BUTTON
class NavigationWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const NavigationWrapper({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CRITICAL FIX: Prevent scaffold from resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main content
          widget.child,
          
          // STATIC bottom navigation - positioned absolutely
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavBarTap,
            ),
          ),
          
          // STATIC scanner button - positioned absolutely
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 32.5, // Center horizontally
            bottom: 55, // Fixed position from bottom
            child: const CustomFloatingActionButton(),
          ),
        ],
      ),
    );
  }
}

// Screen Index Helper Class
class NavigationHelper {
  static const int homeIndex = 0;
  static const int cartIndex = 1;
  static const int wishlistIndex = 2;
  static const int profileIndex = 3;
  
  static Widget getScreenByIndex(int index) {
    switch (index) {
      case homeIndex:
        return const NavigationWrapper(
          child: HomeScreen(),
          initialIndex: homeIndex,
        );
      case cartIndex:
        return const NavigationWrapper(
          child: CartScreen(),
          initialIndex: cartIndex,
        );
      case wishlistIndex:
        return const NavigationWrapper(
          child: WishlistScreen(),
          initialIndex: wishlistIndex,
        );
      case profileIndex:
        return const NavigationWrapper(
          child: ProfileScreen(),
          initialIndex: profileIndex,
        );
      default:
        return const NavigationWrapper(
          child: HomeScreen(),
          initialIndex: homeIndex,
        );
    }
  }
  
  static String getScreenNameByIndex(int index) {
    switch (index) {
      case homeIndex:
        return 'Home';
      case cartIndex:
        return 'Cart';
      case wishlistIndex:
        return 'Wishlist';
      case profileIndex:
        return 'Profile';
      default:
        return 'Home';
    }
  }
}