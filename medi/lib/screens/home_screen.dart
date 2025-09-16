import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/medicine.dart';
import '../widgets/product_card.dart';
import '../widgets/navigation.dart';
import 'cart_screen.dart';
import 'scanner_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'all_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _productScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  
  // API Data
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoadingMedicines = false;
  String? _errorMessage;

  // Banner data with images instead of gradients
  // Replace your _bannerData in HomeScreen with this:
final List<Map<String, dynamic>> _bannerData = [
  {
    'discount': '30% OFF',
    'subtitle': 'On Tablets',
    'title': 'Exclusive Sales',
    'imageUrl': 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=400&h=200&fit=crop', // Tablets/Pills image
    'backgroundColor': const Color(0xFF4A90E2),
  },
  {
    'discount': '25% OFF',
    'subtitle': 'On Syrups',
    'title': 'Special Offer',
    'imageUrl': 'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=400&h=200&fit=crop', // Medicine bottles
    'backgroundColor': const Color(0xFFFF6B6B),
  },
  {
    'discount': '40% OFF',
    'subtitle': 'On Health Care',
    'title': 'Mega Sale',
    'imageUrl': 'https://plus.unsplash.com/premium_photo-1661775601929-8c775187bea6?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8aGVhbHRoJTIwY2FyZSUyMHdvcmtlcnxlbnwwfHwwfHx8MA%3D%3D', // Medical supplies
    'backgroundColor': const Color(0xFF4ECDC4),
  },
  // {
  //   'discount': '20% OFF',
  //   'subtitle': 'On Supplements',
  //   'title': 'Health Boost',
  //   'imageUrl': 'https://images.unsplash.com/photo-1550572017-edd951b51299?w=400&h=200&fit=crop', // Supplement bottles
  //   'backgroundColor': const Color(0xFF9B59B6),
  // },
];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _startBannerAutoScroll();
    _searchController.addListener(_onSearchChanged);
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentBannerIndex < _bannerData.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = _medicines;
      } else {
        _filteredMedicines = _medicines.where((medicine) {
          return medicine.name.toLowerCase().contains(query) ||
                 (medicine.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoadingMedicines = true;
      _errorMessage = null;
    });

    try {
      final medicines = await ApiService.fetchMedicines();
      setState(() {
        _medicines = medicines;
        _filteredMedicines = medicines;
        _isLoadingMedicines = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingMedicines = false;
      });
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _onScannerTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
  }

  void _navigateToAllProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllProductsScreen(medicines: _filteredMedicines),
      ),
    );
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    _searchController.dispose();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8B3FF),
              Color(0xFFF0C4FF),
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Fixed Header
              Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    // Top Header with Profile, App Title, and Cart
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(Icons.person, size: 24),
                            ),
                          ),
                          const Text(
                            'MediScan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(Icons.shopping_cart, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Enhanced Curved Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.7),
                              blurRadius: 10,
                              spreadRadius: -5,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicines, health products...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.mic,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMedicines,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auto-scrolling Promotional Banner Carousel with Images
                        _buildPromotionalCarousel(),

                        const SizedBox(height: 20),

                        // Category Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF7B68EE),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Category Icons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCategoryItem(
                                icon: Icons.medication,
                                label: 'Tablets',
                                color: const Color(0xFFFF6B6B),
                              ),
                              _buildCategoryItem(
                                icon: Icons.local_drink,
                                label: 'Syrups',
                                color: const Color(0xFF4ECDC4),
                              ),
                              _buildCategoryItem(
                                icon: Icons.healing,
                                label: 'Ointments',
                                color: const Color.fromARGB(255, 255, 213, 0),
                              ),
                              _buildCategoryItem(
                                icon: Icons.water_drop,
                                label: 'Drops',
                                color: const Color(0xFF95E1D3),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Featured Products Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _searchController.text.isEmpty 
                                    ? 'Featured Products' 
                                    : 'Search Results (${_filteredMedicines.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: _navigateToAllProducts,
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF7B68EE),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Featured Products Section - From API
                        _buildFeaturedProductsSection(),

                        const SizedBox(height: 100), // Bottom padding for nav bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // In HomeScreen's build method, add these properties to the Scaffold:
bottomNavigationBar: CustomBottomNavBar(
  currentIndex: _selectedIndex,
  onTap: _onNavBarTap,
),
floatingActionButton: CustomFloatingActionButton(onTap: _onScannerTap),
floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // SOLUTION 1: Add better debug information to see what's happening
// Replace your _buildPromotionalCarousel method with this version:

Widget _buildPromotionalCarousel() {
  return SizedBox(
    height: 180,
    child: PageView.builder(
      controller: _bannerController,
      onPageChanged: (index) {
        setState(() {
          _currentBannerIndex = index;
        });
      },
      itemCount: _bannerData.length,
      itemBuilder: (context, index) {
        final banner = _bannerData[index];
        final String imageUrl = banner['imageUrl'] as String? ?? '';
        final String discount = banner['discount'] as String? ?? '';
        final String subtitle = banner['subtitle'] as String? ?? '';
        final String title = banner['title'] as String? ?? '';
        final Color backgroundColor = banner['backgroundColor'] as Color? ?? const Color(0xFF4A90E2);
        
        // DEBUG: Print the image URL to console
        print('Loading banner image: $imageUrl');
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
              ),
              child: Stack(
                children: [
                  // Background Image with better error handling
                  if (imageUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // DEBUG: Print error to console
                          print('Image load error for $imageUrl: $error');
                          
                          // Fallback to solid color if image fails to load
                          return Container(
                            color: backgroundColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image failed to load',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            // DEBUG: Image loaded successfully
                            print('Image loaded successfully: $imageUrl');
                            return child;
                          }
                          
                          // DEBUG: Image is loading
                          print('Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? 'unknown'} bytes');
                          
                          return Container(
                            color: backgroundColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white.withOpacity(0.7),
                                    strokeWidth: 3,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Loading image...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    // DEBUG: Show when imageUrl is empty
                    Positioned.fill(
                      child: Container(
                        color: backgroundColor,
                        child: Center(
                          child: Text(
                            'No image URL provided',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // Dark overlay for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  
                  // Decorative circles
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  
                  // Content
                  Positioned(
                    left: 24,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 50,
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 20,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Page indicators
                  Positioned(
                    bottom: 12,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _bannerData.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentBannerIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}




  // Widget _buildPromotionalCarousel() {
  //   return SizedBox(
  //     height: 180,
  //     child: PageView.builder(
  //       controller: _bannerController,
  //       onPageChanged: (index) {
  //         setState(() {
  //           _currentBannerIndex = index;
  //         });
  //       },
  //       itemCount: _bannerData.length,
  //       itemBuilder: (context, index) {
  //         final banner = _bannerData[index];
  //         final String imageUrl = banner['imageUrl'] as String? ?? '';
  //         final String discount = banner['discount'] as String? ?? '';
  //         final String subtitle = banner['subtitle'] as String? ?? '';
  //         final String title = banner['title'] as String? ?? '';
  //         final Color backgroundColor = banner['backgroundColor'] as Color? ?? const Color(0xFF4A90E2);
          
  //         return Container(
  //           margin: const EdgeInsets.symmetric(horizontal: 20),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(20),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.15),
  //                 blurRadius: 15,
  //                 offset: const Offset(0, 8),
  //               ),
  //             ],
  //           ),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(20),
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 color: banner['backgroundColor'],
  //               ),
  //               child: Stack(
  //                 children: [
  //                   // Background Image
  //                   if (imageUrl.isNotEmpty)
  //                     Positioned.fill(
  //                       child: Image.network(
  //                         imageUrl,
  //                         fit: BoxFit.cover,
  //                         errorBuilder: (context, error, stackTrace) {
  //                           // Fallback to solid color if image fails to load
  //                           return Container(
  //                             color: backgroundColor,
  //                             child: Center(
  //                               child: Icon(
  //                                 Icons.image_not_supported,
  //                                 color: Colors.white.withOpacity(0.5),
  //                                 size: 50,
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                         loadingBuilder: (context, child, loadingProgress) {
  //                           if (loadingProgress == null) return child;
  //                           return Container(
  //                             color: backgroundColor,
  //                             child: Center(
  //                               child: CircularProgressIndicator(
  //                                 color: Colors.white.withOpacity(0.7),
  //                                 value: loadingProgress.expectedTotalBytes != null
  //                                     ? loadingProgress.cumulativeBytesLoaded /
  //                                         (loadingProgress.expectedTotalBytes ?? 1)
  //                                     : null,
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   // Dark overlay for better text readability
  //                   Positioned.fill(
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         gradient: LinearGradient(
  //                           colors: [
  //                             Colors.black.withOpacity(0.4),
  //                             Colors.transparent,
  //                             Colors.black.withOpacity(0.6),
  //                           ],
  //                           begin: Alignment.topLeft,
  //                           end: Alignment.bottomRight,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   // Decorative circles
  //                   Positioned(
  //                     right: -30,
  //                     top: -30,
  //                     child: Container(
  //                       width: 100,
  //                       height: 100,
  //                       decoration: BoxDecoration(
  //                         color: Colors.white.withOpacity(0.1),
  //                         shape: BoxShape.circle,
  //                       ),
  //                     ),
  //                   ),
  //                   Positioned(
  //                     right: -10,
  //                     bottom: -20,
  //                     child: Container(
  //                       width: 60,
  //                       height: 60,
  //                       decoration: BoxDecoration(
  //                         color: Colors.white.withOpacity(0.1),
  //                         shape: BoxShape.circle,
  //                       ),
  //                     ),
  //                   ),
  //                   // Content
  //                   Positioned(
  //                     left: 24,
  //                     top: 20,
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: Colors.red,
  //                         borderRadius: BorderRadius.circular(15),
  //                       ),
  //                       child: Text(
  //                         discount,
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   Positioned(
  //                     left: 24,
  //                     bottom: 50,
  //                     child: Text(
  //                       subtitle,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w500,
  //                         shadows: [
  //                           Shadow(
  //                             color: Colors.black54,
  //                             offset: Offset(0, 1),
  //                             blurRadius: 2,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   Positioned(
  //                     left: 24,
  //                     bottom: 20,
  //                     child: Text(
  //                       title,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.bold,
  //                         shadows: [
  //                           Shadow(
  //                             color: Colors.black54,
  //                             offset: Offset(0, 1),
  //                             blurRadius: 3,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   // Page indicators
  //                   Positioned(
  //                     bottom: 12,
  //                     right: 20,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: _bannerData.asMap().entries.map((entry) {
  //                         return Container(
  //                           width: 8,
  //                           height: 8,
  //                           margin: const EdgeInsets.symmetric(horizontal: 3),
  //                           decoration: BoxDecoration(
  //                             shape: BoxShape.circle,
  //                             color: _currentBannerIndex == entry.key
  //                                 ? Colors.white
  //                                 : Colors.white.withOpacity(0.5),
  //                           ),
  //                         );
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildFeaturedProductsSection() {
    if (_isLoadingMedicines) {
      return SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) => _buildLoadingCard(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Error loading products: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadMedicines,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredMedicines.isEmpty) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, color: Colors.grey[400], size: 50),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty 
                    ? 'No products available'
                    : 'No products found for "${_searchController.text}"',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                TextButton(
                  onPressed: () => _searchController.clear(),
                  child: const Text('Clear search'),
                ),
            ],
          ),
        ),
      );
    }

    final displayMedicines = _searchController.text.isEmpty 
        ? _filteredMedicines.take(6).toList() 
        : _filteredMedicines;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _productScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayMedicines.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final medicine = displayMedicines[index];
          return SizedBox(
            width: 300,
            child: ProductCard(medicine: medicine),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected $label category'),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}