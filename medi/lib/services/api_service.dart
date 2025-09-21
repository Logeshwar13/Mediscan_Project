import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import '../models/user.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = "https://9f3ad419f2a5.ngrok-free.app/api";

  static String? _currentUserId;
  static String? _authToken;

  static void setCurrentUser(String userId, String token) {
    _currentUserId = userId;
    _authToken = token;
  }

  static void clearUserData() {
    _currentUserId = null;
    _authToken = null;
  }

  static Map<String, String> _getAuthHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ----------------- User Auth -----------------
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserModel.fromJson(data['user']);

        if (data['token'] != null) {
          setCurrentUser(user.id, data['token']);
        }

        return {
          'success': true,
          'user': user,
          'token': data['token'],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? "Signup failed"};
      }
    } catch (e) {
      return {'success': false, 'error': "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);

        if (data['token'] != null) {
          setCurrentUser(user.id, data['token']);
        }

        return {
          'success': true,
          'user': user,
          'token': data['token'],
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        return {'success': false, 'error': data['error'] ?? "Login failed"};
      }
    } catch (e) {
      return {'success': false, 'error': "Network error: $e"};
    }
  }

  // ----------------- Profile Update -----------------
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? address,
  }) async {
    if (_currentUserId == null || _authToken == null) {
      return {'success': false, 'error': "User not logged in"};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'name': name, 'phone': phone, 'address': address}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        return {
          'success': true,
          'user': user,
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? "Profile update failed",
        };
      }
    } catch (e) {
      return {'success': false, 'error': "Network error: $e"};
    }
  }

  // ----------------- Order Tracking -----------------
  static Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    if (_authToken == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/tracking/$orderId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'currentLocationIndex': data['currentLocationIndex'] ?? 2,
          'locationUpdates': data['locationUpdates'] ?? [
            "Left MediCare Pharmacy",
            "On Anna Salai Road", 
            "Approaching T. Nagar",
            "Near delivery area"
          ],
          'estimatedTime': data['estimatedTime'] ?? "15-20 minutes",
          'deliveryPersonLocation': data['deliveryPersonLocation'] ?? {
            'lat': 13.0827,
            'lng': 80.2707
          },
          'deliveryPersonName': data['deliveryPersonName'] ?? "Rajesh Kumar",
          'deliveryPersonPhone': data['deliveryPersonPhone'] ?? "+91 9786001567",
          'deliveryPersonRating': data['deliveryPersonRating'] ?? 4.8,
          'currentStatus': data['currentStatus'] ?? "Out for Delivery"
        };
      } else {
        throw Exception("Failed to get order tracking");
      }
    } catch (e) {
      // Return mock data if API fails
      return {
        'success': false,
        'error': e.toString(),
        'currentLocationIndex': 2,
        'locationUpdates': [
          "Left MediCare Pharmacy",
          "On Anna Salai Road", 
          "Approaching T. Nagar",
          "Near delivery area"
        ],
        'estimatedTime': "15-20 minutes",
        'deliveryPersonLocation': {
          'lat': 13.0827,
          'lng': 80.2707
        },
        'deliveryPersonName': "Rajesh Kumar",
        'deliveryPersonPhone': "+91 9786001567", 
        'deliveryPersonRating': 4.8,
        'currentStatus': "Out for Delivery"
      };
    }
  }

  // ----------------- Get Current User Profile -----------------
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (_authToken == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['user']; // return user object (with phone, name, etc.)
      } else {
        throw Exception(data['error'] ?? "Failed to load profile");
      }
    } catch (e) {
      throw Exception("Profile fetch error: $e");
    }
  }

  // ----------------- Medicines -----------------
  static Future<List<Medicine>> fetchMedicines() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicines'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Medicine.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load medicines: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Search medicines
  static Future<List<Medicine>> searchMedicines(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicines/search?q=$query'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Medicine.fromJson(json)).toList();
      } else {
        throw Exception("Search failed");
      }
    } catch (e) {
      throw Exception("Search error: $e");
    }
  }

  static Future<void> removeFromWishlist(String medicineId) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/remove'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'userId': _currentUserId, 'medicineId': medicineId}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to remove from wishlist");
      }
    } catch (e) {
      throw Exception("Remove from wishlist error: $e");
    }
  }

  static Future<List<Medicine>> scanPrescription(String imagePath) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/scan"));

      request.files.add(await http.MultipartFile.fromPath("image", imagePath));

      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200 && data["success"] == true) {
        final List medicines = data["medicines"];
        return medicines.map((json) => Medicine.fromJson(json)).toList();
      } else {
        throw Exception(data["error"] ?? "Prescription scan failed");
      }
    } catch (e) {
      throw Exception("Scan error: $e");
    }
  }

  // ----------------- Cart Management -----------------
  static Future<void> addToCart(String medicineId, {int quantity = 1}) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'userId': _currentUserId,
          'medicineId': medicineId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Failed to add to cart");
      }
    } catch (e) {
      throw Exception("Add to cart error: $e");
    }
  }

  static Future<List<dynamic>> getCartItems() async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/$_currentUserId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load cart");
      }
    } catch (e) {
      throw Exception("Cart fetch error: $e");
    }
  }

  static Future<void> removeFromCart(String medicineId) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'userId': _currentUserId, 'medicineId': medicineId}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to remove from cart");
      }
    } catch (e) {
      throw Exception("Remove from cart error: $e");
    }
  }

  static Future<void> updateCartQuantity(
    String medicineId,
    int quantity,
  ) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update'),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'userId': _currentUserId,
          'medicineId': medicineId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update cart");
      }
    } catch (e) {
      throw Exception("Update cart error: $e");
    }
  }

  static Future<void> clearCart() async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/clear/$_currentUserId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to clear cart");
      }
    } catch (e) {
      throw Exception("Clear cart error: $e");
    }
  }

  // ----------------- Orders -----------------
  static Future<List<Order>> fetchOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/$userId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load orders");
      }
    } catch (e) {
      throw Exception("Order fetch error: $e");
    }
  }

  static Future<Order> createOrder(List<String> medicineIds) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'userId': _currentUserId, 'medicines': medicineIds}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Failed to create order");
      }
    } catch (e) {
      throw Exception("Create order error: $e");
    }
  }

  static Future<Order> createOrderFromCart() async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/from-cart'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'userId': _currentUserId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? "Failed to create order from cart",
        );
      }
    } catch (e) {
      throw Exception("Create order from cart error: $e");
    }
  }

  // ----------------- Get Profile -----------------
  static Future<Map<String, dynamic>> getProfile() async {
    if (_currentUserId == null || _authToken == null) {
      return {'success': false, 'error': "User not logged in"};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        return {
          'success': true,
          'user': user,
          'message': 'Profile retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? "Failed to get profile",
        };
      }
    } catch (e) {
      return {'success': false, 'error': "Network error: $e"};
    }
  }

  // ----------------- Wishlist -----------------
  static Future<void> addToWishlist(String medicineId) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/add'),
        headers: _getAuthHeaders(),
        body: jsonEncode({'userId': _currentUserId, 'medicineId': medicineId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to add to wishlist");
      }
    } catch (e) {
      throw Exception("Add to wishlist error: $e");
    }
  }

  static Future<List<Medicine>> getWishlistItems() async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/$_currentUserId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Medicine.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load wishlist");
      }
    } catch (e) {
      throw Exception("Wishlist fetch error: $e");
    }
  }

  // ----------------- Utility Methods -----------------
  static bool get isLoggedIn => _currentUserId != null && _authToken != null;
  static String? get currentUserId => _currentUserId;
}