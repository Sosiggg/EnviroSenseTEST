import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/sensor/sensor_bloc.dart';
import '../../blocs/sensor/sensor_event.dart';
import '../../blocs/sensor/sensor_state.dart';
import '../auth/login_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'team_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProfilePage(),
    const TeamPage(),
  ];

  @override
  void initState() {
    super.initState();

    // Connect to WebSocket for real-time updates
    context.read<SensorBloc>().add(const SensorWebSocketConnectRequested());
  }

  @override
  void dispose() {
    // Disconnect from WebSocket
    context.read<SensorBloc>().add(const SensorWebSocketDisconnectRequested());
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    AppLogger.i('HomePage: Starting logout process');

    try {
      // Get the blocs before any async operations
      final sensorBloc = context.read<SensorBloc>();
      final authBloc = context.read<AuthBloc>();

      // First disconnect WebSocket
      sensorBloc.add(const SensorWebSocketDisconnectRequested());

      // Wait a moment for the disconnection to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if widget is still mounted before continuing
      if (!mounted) {
        AppLogger.w('HomePage: Widget unmounted during logout process');
        return;
      }

      // Then clear sensor data
      sensorBloc.add(const SensorDataClearRequested());

      // Wait a moment for the data clear to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if widget is still mounted before continuing
      if (!mounted) {
        AppLogger.w('HomePage: Widget unmounted during logout process');
        return;
      }

      // Perform a complete reset of the SensorBloc
      sensorBloc.add(const SensorResetRequested());

      // Wait a moment for the reset to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if widget is still mounted before continuing
      if (!mounted) {
        AppLogger.w('HomePage: Widget unmounted during logout process');
        return;
      }

      // Finally logout - this will clear the token and user cache
      authBloc.add(const AuthLogoutRequested());

      AppLogger.i('HomePage: Logout process completed successfully');
    } catch (e) {
      AppLogger.e('HomePage: Error during logout: $e', e);

      // Even if there's an error, try to logout if still mounted
      if (mounted) {
        context.read<AuthBloc>().add(const AuthLogoutRequested());
      }
    }
  }

  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Extra small screen detection

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else if (state is AuthLoginSuccess) {
          // When a new user logs in, force refresh the profile page
          AppLogger.i('HomePage: New login detected, refreshing profile data');

          // Reset to dashboard on new login
          setState(() {
            _selectedIndex = 0;
          });

          // Request fresh user profile data
          context.read<AuthBloc>().add(const AuthGetUserProfileRequested());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'EnviroSense',
            style: TextStyle(
              fontSize:
                  isSmallScreen ? 18 : 20, // Smaller font on small screens
            ),
          ),
          actions: [
            // Connection status indicator
            BlocBuilder<SensorBloc, SensorState>(
              builder: (context, state) {
                final bool isConnected =
                    state is! SensorInitial && state is! SensorFailure;

                // Only show on larger screens, drawer will have this on small screens
                if (!isSmallScreen) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: isConnected ? 'Connected' : 'Disconnected',
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),

            // Theme Toggle - use smaller icon on small screens
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: isSmallScreen ? 20 : 24,
              ),
              visualDensity:
                  isSmallScreen
                      ? const VisualDensity(horizontal: -1, vertical: -1)
                      : null,
              onPressed: _toggleTheme,
            ),

            // Logout - use smaller icon on small screens
            IconButton(
              icon: Icon(Icons.logout, size: isSmallScreen ? 20 : 24),
              visualDensity:
                  isSmallScreen
                      ? const VisualDensity(horizontal: -1, vertical: -1)
                      : null,
              onPressed: _logout,
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                // Responsive drawer header
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 16 : 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // User avatar
                          CircleAvatar(
                            radius: isSmallScreen ? 24 : 30,
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 24 : 30,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Connection status indicator
                          BlocBuilder<SensorBloc, SensorState>(
                            builder: (context, state) {
                              final bool isConnected =
                                  state is! SensorInitial &&
                                  state is! SensorFailure;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isConnected
                                          ? Colors.green.withAlpha(50)
                                          : Colors.red.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isConnected
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isConnected
                                          ? 'Connected'
                                          : 'Disconnected',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // User info
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthAuthenticated) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.user.username,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.user.email,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                // Scrollable menu items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: const Text('Dashboard'),
                        selected: _selectedIndex == 0,
                        dense: isSmallScreen, // More compact on small screens
                        visualDensity:
                            isSmallScreen
                                ? const VisualDensity(vertical: -1)
                                : null,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        selected: _selectedIndex == 1,
                        dense: isSmallScreen,
                        visualDensity:
                            isSmallScreen
                                ? const VisualDensity(vertical: -1)
                                : null,
                        onTap: () {
                          _onItemTapped(1);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: const Text('Team'),
                        selected: _selectedIndex == 2,
                        dense: isSmallScreen,
                        visualDensity:
                            isSmallScreen
                                ? const VisualDensity(vertical: -1)
                                : null,
                        onTap: () {
                          _onItemTapped(2);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        title: Text(
                          themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        ),
                        dense: isSmallScreen,
                        visualDensity:
                            isSmallScreen
                                ? const VisualDensity(vertical: -1)
                                : null,
                        onTap: () {
                          _toggleTheme();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        dense: isSmallScreen,
                        visualDensity:
                            isSmallScreen
                                ? const VisualDensity(vertical: -1)
                                : null,
                        onTap: () {
                          Navigator.pop(context);
                          _logout();
                        },
                      ),
                    ],
                  ),
                ),

                // App version at bottom
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'EnviroSense v1.0.0',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: isSmallScreen ? 20 : 24),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: isSmallScreen ? 20 : 24),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group, size: isSmallScreen ? 20 : 24),
              label: 'Team',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedFontSize: isSmallScreen ? 11 : 14,
          unselectedFontSize: isSmallScreen ? 11 : 12,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
