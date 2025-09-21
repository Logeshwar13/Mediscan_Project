import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // For phone calls and SMS
import 'dart:async';
import 'package:flutter/services.dart'; // Add this import at the top
import '../models/order.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _updateTimer;
  
  // Map controller
  final MapController _mapController = MapController();
  
  // Puducherry location coordinates
  LatLng _deliveryPersonLocation = const LatLng(11.9416, 79.8083); // Current location in Puducherry
  final LatLng _customerLocation = const LatLng(11.9139, 79.8145); // White Town, Puducherry
  final LatLng _pharmacyLocation = const LatLng(11.9416, 79.8083); // MediCare Pharmacy, Puducherry
  
  // Mock tracking data - replace with real API calls
  final String _deliveryPersonName = "Cristiano Ronaldo";
  final String _deliveryPersonPhone = "+919786001567"; // Updated format for calling
  final double _deliveryPersonRating = 4.8;
  String _currentStatus = "Out for Delivery";
  String _estimatedTime = "15-20 minutes";
  String _lastUpdate = "2 minutes ago";
  
  // Puducherry location updates simulation
  final List<Map<String, dynamic>> _locationUpdates = [
    {"text": "Left MediCare Pharmacy", "location": const LatLng(11.9416, 79.8083)},
    {"text": "On Jawaharlal Nehru Street", "location": const LatLng(11.9350, 79.8100)},
    {"text": "Approaching White Town", "location": const LatLng(11.9250, 79.8120)},
    {"text": "Near delivery area", "location": const LatLng(11.9139, 79.8145)},
  ];
  int _currentLocationIndex = 2;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLocationUpdates();
    _requestLocationPermission();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }
  }

  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentLocationIndex < _locationUpdates.length - 1) {
        setState(() {
          _currentLocationIndex++;
          _deliveryPersonLocation = _locationUpdates[_currentLocationIndex]["location"];
          _lastUpdate = "Just now";
        });
        
        // Update map camera to follow delivery person
        try {
          _mapController.move(_deliveryPersonLocation, 15.0);
        } catch (e) {
          debugPrint('Map controller error: $e');
        }
        
        // Update estimated time as delivery person gets closer
        if (_currentLocationIndex >= _locationUpdates.length - 1) {
          setState(() {
            _estimatedTime = "5-10 minutes";
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  // Debug function to test different phone number formats
  void _debugPhoneCall() async {
    final testNumbers = [
      'tel:9786001567',
      'tel:+919786001567', 
      'tel://9786001567',
      'tel://+919786001567'
    ];
    
    debugPrint('=== Phone Call Debug Test ===');
    for (String number in testNumbers) {
      try {
        final uri = Uri.parse(number);
        final canLaunch = await canLaunchUrl(uri);
        debugPrint('$number - Can Launch: $canLaunch');
        
        // Also test with Uri constructor
        final uriConstructor = Uri(scheme: 'tel', path: number.replaceAll('tel:', '').replaceAll('//', ''));
        final canLaunchConstructor = await canLaunchUrl(uriConstructor);
        debugPrint('${uriConstructor.toString()} (Uri constructor) - Can Launch: $canLaunchConstructor');
      } catch (e) {
        debugPrint('$number - Error: $e');
      }
    }
    debugPrint('=== End Debug Test ===');
  }

  // Enhanced phone call functionality with better error handling and debug integration
  void _callDeliveryPerson() async {
    try {
      // Run debug test first (can be removed in production)
      if (kDebugMode) {
        _debugPhoneCall(); //await 
      }
      
      // Remove the + symbol and format the number properly
      final phoneNumber = _deliveryPersonPhone.replaceAll('+', '');
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      
      debugPrint('Attempting to call: $phoneNumber');
      debugPrint('Generated URI: ${phoneUri.toString()}');
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication, // Force external app
        );
        debugPrint('Call launched successfully');
      } else {
        debugPrint('Primary call method failed, trying alternatives');
        // Fallback: try with different formats
        await _tryAlternateCallMethods();
      }
    } catch (e) {
      debugPrint('Call error: $e');
      await _tryAlternateCallMethods();
    }
  }

  // Enhanced alternative methods for making calls with more format options
  Future<void> _tryAlternateCallMethods() async {
    final alternativeMethods = [
      // Method 1: Try without country code
      {'number': '9786001567', 'description': 'Local number without country code'},
      
      // Method 2: Try with country code using Uri constructor
      {'number': '+919786001567', 'description': 'Full international format'},
      
      // Method 3: Try with country code but no plus sign
      {'number': '919786001567', 'description': 'International without plus'},
      
      // Method 4: Try with different URI parsing
      {'number': '9786001567', 'description': 'Local with Uri.parse'},
    ];
    
    for (var method in alternativeMethods) {
      try {
        debugPrint('Trying method: ${method['description']}');
        
        Uri? uri;
        if (method['description'].toString().contains('Uri.parse')) {
          uri = Uri.parse('tel:${method['number']}');
        } else {
          uri = Uri(scheme: 'tel', path: method['number'].toString());
        }
        
        debugPrint('Generated URI: ${uri.toString()}');
        
        if (await canLaunchUrl(uri)) {
          debugPrint('Method succeeded: ${method['description']}');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return; // Success, exit the loop
        } else {
          debugPrint('Method failed: ${method['description']}');
        }
      } catch (e) {
        debugPrint('Error with method ${method['description']}: $e');
        continue;
      }
    }
    
    // All methods failed, show manual dial option
    debugPrint('All call methods failed, showing manual dial option');
    if (mounted) {
      _showManualDialOption();
    }
  }

  // Enhanced manual dial option with better debugging info
  void _showManualDialOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Auto-Dial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please manually dial this number:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _deliveryPersonPhone,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(_deliveryPersonPhone),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy number',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the copy button to copy the number to your clipboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // Debug info (can be removed in production)
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              const Text(
                'Debug Info:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Check console for detailed call attempt logs',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(_deliveryPersonPhone);
            },
            child: const Text('Copy Number'),
          ),
          // Debug button (can be removed in production)
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _debugPhoneCall();
              },
              child: const Text('Run Debug'),
            ),
        ],
      ),
    );
  }

  // Copy number to clipboard with enhanced feedback
  void _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      debugPrint('Copied to clipboard: $text');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text copied to clipboard'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Clipboard error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Enhanced SMS functionality with debug capabilities
  void _sendSMS(String message) async {
    try {
      Navigator.pop(context); // Close dialog first
      
      if (kDebugMode) {
        debugPrint('=== SMS Debug Test ===');
      }
      
      // Try multiple SMS URI formats with debugging
      final List<Map<String, dynamic>> smsFormats = [
        {
          'uri': Uri(scheme: 'sms', path: _deliveryPersonPhone, queryParameters: {'body': message}),
          'description': 'Uri constructor with original number'
        },
        {
          'uri': Uri(scheme: 'sms', path: _deliveryPersonPhone.replaceAll('+', ''), queryParameters: {'body': message}),
          'description': 'Uri constructor without plus sign'
        },
        {
          'uri': Uri.parse('sms:${_deliveryPersonPhone.replaceAll('+', '')}?body=${Uri.encodeComponent(message)}'),
          'description': 'Uri.parse format'
        },
        {
          'uri': Uri(scheme: 'sms', path: '9786001567', queryParameters: {'body': message}),
          'description': 'Local number only'
        },
      ];
      
      bool smsSent = false;
      
      for (var format in smsFormats) {
        try {
          debugPrint('Trying SMS method: ${format['description']}');
          debugPrint('Generated URI: ${format['uri'].toString()}');
          
          if (await canLaunchUrl(format['uri'])) {
            debugPrint('SMS method succeeded: ${format['description']}');
            await launchUrl(format['uri'], mode: LaunchMode.externalApplication);
            smsSent = true;
            break;
          } else {
            debugPrint('SMS method failed: ${format['description']}');
          }
        } catch (e) {
          debugPrint('SMS attempt failed for ${format['description']}: $e');
          continue;
        }
      }
      
      if (kDebugMode) {
        debugPrint('=== End SMS Debug Test ===');
      }
      
      if (!smsSent) {
        debugPrint('All SMS methods failed, showing manual option');
        _showManualSMSOption(message);
      }
    } catch (e) {
      debugPrint('SMS error: $e');
      if (mounted) {
        _showManualSMSOption(message);
      }
    }
  }

  // Enhanced manual SMS option
  void _showManualSMSOption(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Send SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please manually send this message:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('To: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(_deliveryPersonPhone)),
                      IconButton(
                        onPressed: () => _copyToClipboard(_deliveryPersonPhone),
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Message: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(message)),
                      IconButton(
                        onPressed: () => _copyToClipboard(message),
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Debug info (can be removed in production)
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              const Text(
                'Debug: Check console for SMS attempt details',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard('$_deliveryPersonPhone\n\n$message');
            },
            child: const Text('Copy All'),
          ),
        ],
      ),
    );
  }

  // Enhanced contact support with debug capabilities
  void _contactSupport() async {
    try {
      debugPrint('Attempting to contact support...');
      const supportPhone = '9786001567'; // Try without country code first
      final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
      
      debugPrint('Support URI: ${phoneUri.toString()}');
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        debugPrint('Support call launched successfully');
      } else {
        // Try with country code
        final Uri altPhoneUri = Uri(scheme: 'tel', path: '+919786001567');
        debugPrint('Trying alternative support URI: ${altPhoneUri.toString()}');
        
        if (await canLaunchUrl(altPhoneUri)) {
          await launchUrl(altPhoneUri, mode: LaunchMode.externalApplication);
          debugPrint('Alternative support call launched successfully');
        } else {
          debugPrint('Both support call methods failed');
          _showSupportContactOptions();
        }
      }
    } catch (e) {
      debugPrint('Support contact error: $e');
      _showSupportContactOptions();
    }
  }

  // Enhanced support contact options
  void _showSupportContactOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Support'),
              subtitle: const Text('+91 9786001567'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard('+919786001567');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('support@medicare.com'),
              onTap: () {
                Navigator.pop(context);
                _launchEmail();
              },
            ),
            // Debug option (can be removed in production)
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Run Phone Debug'),
                subtitle: const Text('Test phone call formats'),
                onTap: () {
                  Navigator.pop(context);
                  _debugPhoneCall();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Launch email app with enhanced error handling
  void _launchEmail() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@medicare.com',
        queryParameters: {
          'subject': 'Order Support - ${widget.order.id.substring(0, 8).toUpperCase()}',
          'body': 'Hi, I need help with my order...',
        },
      );
      
      debugPrint('Email URI: ${emailUri.toString()}');
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        debugPrint('Email launched successfully');
      } else {
        debugPrint('Email launch failed, copying address to clipboard');
        _copyToClipboard('support@medicare.com');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email address copied to clipboard'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
      _copyToClipboard('support@medicare.com');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Track Your Order',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Order Status Header
          _buildOrderStatusHeader(),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Map Card
                  _buildMapCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Live Tracking Card
                  _buildLiveTrackingCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Delivery Person Card
                  _buildDeliveryPersonCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Order Progress Timeline
                  _buildOrderTimeline(),
                  
                  const SizedBox(height: 20),
                  
                  // Order Summary Card
                  _buildOrderSummaryCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Help & Support
                  _buildHelpSupportCard(),
                  
                  const SizedBox(height: 100), // Extra space for better scrolling
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B68EE), Color(0xFF9575FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _deliveryPersonLocation,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.medi',
                ),
                MarkerLayer(
                  markers: [
                    // Pharmacy marker
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _pharmacyLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Delivery person marker with animation
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: _deliveryPersonLocation,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B68EE).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B68EE),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Customer location marker
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _customerLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_pharmacyLocation, _deliveryPersonLocation, _customerLocation],
                      strokeWidth: 4.0,
                      color: const Color(0xFF7B68EE).withOpacity(0.8),
                      isDotted: false,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B68EE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B68EE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Pharmacy', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B68EE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Delivery', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('You', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B68EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF7B68EE),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Live Location Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Location Timeline
          Column(
            children: _locationUpdates.asMap().entries.map((entry) {
              int index = entry.key;
              String location = entry.value["text"];
              bool isActive = index == _currentLocationIndex;
              bool isPassed = index < _currentLocationIndex;
              
              return _buildLocationTimelineItem(
                location: location,
                isActive: isActive,
                isPassed: isPassed,
                isLast: index == _locationUpdates.length - 1,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Estimated Time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated arrival: $_estimatedTime',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Updated $_lastUpdate',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTimelineItem({
    required String location,
    required bool isActive,
    required bool isPassed,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFF7B68EE) 
                      : isPassed 
                          ? Colors.green 
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isActive 
                      ? Border.all(color: const Color(0xFF7B68EE).withOpacity(0.3), width: 4)
                      : null,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: isPassed ? Colors.green : Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive 
                            ? const Color(0xFF7B68EE)
                            : isPassed 
                                ? Colors.green
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B68EE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: Color(0xFF7B68EE),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Delivery Partner',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF7B68EE),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryPersonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Delivery Partner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                        Text(
                          ' $_deliveryPersonRating (324 deliveries)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callDeliveryPerson(),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B68EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _messageDeliveryPerson(),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B68EE),
                    side: const BorderSide(color: Color(0xFF7B68EE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            icon: Icons.check_circle,
            title: 'Order Confirmed',
            subtitle: 'Your order has been placed',
            isCompleted: true,
            time: '10:30 AM',
          ),
          _buildTimelineItem(
            icon: Icons.inventory_2,
            title: 'Order Prepared',
            subtitle: 'Medicines packed and ready',
            isCompleted: true,
            time: '11:15 AM',
          ),
          _buildTimelineItem(
            icon: Icons.local_shipping,
            title: 'Out for Delivery',
            subtitle: 'On the way to your address',
            isCompleted: true,
            isActive: true,
            time: '11:45 AM',
          ),
          _buildTimelineItem(
            icon: Icons.home,
            title: 'Delivered',
            subtitle: 'Order successfully delivered',
            isCompleted: false,
            time: 'Expected by 12:30 PM',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String time,
    bool isActive = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? (isActive ? const Color(0xFF7B68EE) : Colors.green)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isActive 
                      ? Border.all(color: const Color(0xFF7B68EE).withOpacity(0.3), width: 4)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted 
                                ? (isActive ? const Color(0xFF7B68EE) : Colors.green)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.order.items.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '₹${widget.order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B68EE),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...widget.order.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.medicine.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )).toList(),
          if (widget.order.items.length > 3)
            Text(
              '+ ${widget.order.items.length - 3} more items',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelpSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactSupport(),
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B68EE),
                    side: const BorderSide(color: Color(0xFF7B68EE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reportIssue(),
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text('Report Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SMS functionality with url_launcher
  void _messageDeliveryPerson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Message'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send a quick message to your delivery partner:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickMessageChip('I\'ll be waiting outside'),
                  _buildQuickMessageChip('Please ring the doorbell'),
                  _buildQuickMessageChip('Call when you arrive'),
                  _buildQuickMessageChip('Running 5 minutes late'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _sendCustomMessage(),
            child: const Text('Custom Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessageChip(String message) {
    return ActionChip(
      label: Text(
        message,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _sendSMS(message),
      backgroundColor: const Color(0xFF7B68EE).withOpacity(0.1),
      labelStyle: const TextStyle(
        color: Color(0xFF7B68EE),
        fontSize: 12,
      ),
    );
  }

  // Function for custom message
  void _sendCustomMessage() {
    Navigator.pop(context); // Close current dialog
    
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Message'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final message = messageController.text.trim();
              if (message.isNotEmpty) {
                Navigator.pop(context);
                _sendSMS(message);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening issue reporting form...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}