import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _editProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    // If profile was updated successfully, refresh the data
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      debugPrint(
        'Profile Screen - Before refresh - User: ${userProvider.user?.name}',
      );
      debugPrint('Profile Screen - Is logged in: ${userProvider.isLoggedIn}');

      // Debug current state
      userProvider.debugCurrentState();

      // Only refresh if user is logged in
      if (userProvider.isLoggedIn) {
        await userProvider.refreshUser();
      }

      debugPrint(
        'Profile Screen - After refresh - User: ${userProvider.user?.name}',
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile Screen - Load user data error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load user data: $e';
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.isDarkMode;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Logout',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.logout();

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUserData,
              ),
            ],
            backgroundColor: isDark
                ? const Color(0xFF1F1F1F)
                : const Color(0xFFE8B3FF),
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1F1F1F),
                        const Color(0xFF2C2C2C),
                        const Color(0xFF121212),
                      ]
                    : [
                        const Color(0xFFE8B3FF),
                        const Color(0xFFF0C4FF),
                        Colors.white,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _buildBody(userProvider, themeProvider),
          ),
        );
      },
    );
  }

  Widget _buildBody(UserProvider userProvider, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    // Show loading if either the screen or provider is loading
    if (isLoading || userProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user data...'),
          ],
        ),
      );
    }

    // Show error if there's an error message
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.red[400] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.red[400] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF7B2CBF)
                    : const Color(0xFFE8B3FF),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Check if user is not logged in
    if (!userProvider.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your profile',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF7B2CBF)
                    : const Color(0xFFE8B3FF),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    // Check if user data is null
    if (userProvider.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: isDark ? Colors.orange[400] : Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No user data available',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or logging in again',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF7B2CBF)
                        : const Color(0xFFE8B3FF),
                  ),
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text('Login Again'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final currentUser = userProvider.user!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Info Card
        Card(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: isDark
                      ? const Color(0xFF7B2CBF)
                      : Theme.of(context).primaryColor,
                  child: Text(
                    (currentUser.name.isNotEmpty ? currentUser.name[0] : 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Personal Information Section
        _buildProfileSection('Personal Information', [
          _buildInfoTile(Icons.person, 'Full Name', currentUser.name, isDark),
          _buildInfoTile(Icons.email, 'Email', currentUser.email, isDark),
          _buildInfoTile(Icons.phone, 'Phone', currentUser.phone, isDark),
          _buildInfoTile(
            Icons.location_on,
            'Address',
            currentUser.address ?? 'Not provided',
            isDark,
          ),
          _buildInfoTile(Icons.badge, 'User ID', currentUser.id, isDark),
        ], isDark),

        const SizedBox(height: 16),

        // Account Actions Section
        _buildProfileSection('Account', [
          ListTile(
            leading: Icon(
              Icons.edit,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            title: Text(
              'Edit Profile',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            onTap: _editProfile,
          ),
          ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: const Color(0xFF7B2CBF),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.security,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            title: Text(
              'Change Password',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password feature coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ], isDark),

        // Add extra bottom padding to ensure full scrollability
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfileSection(
    String title,
    List<Widget> children,
    bool isDark,
  ) {
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white24 : Colors.grey[300]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }
}
