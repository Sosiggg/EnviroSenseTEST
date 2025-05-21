import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/sensor/sensor_bloc.dart';
import '../../blocs/sensor/sensor_event.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get the blocs before any async operations
        final sensorBloc = context.read<SensorBloc>();
        final authBloc = context.read<AuthBloc>();

        // First, ensure WebSocket is disconnected
        sensorBloc.add(const SensorWebSocketDisconnectRequested());

        // Wait a moment for the disconnection to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if widget is still mounted
        if (!mounted) return;

        // Clear any existing sensor data
        sensorBloc.add(const SensorDataClearRequested());

        // Wait a moment for the data clear to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if widget is still mounted
        if (!mounted) return;

        // Reset the SensorBloc to initial state
        sensorBloc.add(const SensorResetRequested());

        // Wait a moment for the reset to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if widget is still mounted
        if (!mounted) return;

        // Clear any cached user data
        authBloc.add(const AuthClearCacheRequested());

        // Wait a moment for the cache clear to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if widget is still mounted
        if (!mounted) return;

        // Then attempt login
        authBloc.add(
          AuthLoginRequested(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );

        AppLogger.i('LoginPage: Login process initiated with complete cleanup');
      } catch (e) {
        AppLogger.e('LoginPage: Error during login preparation: $e', e);

        // If there's an error, still try to login if mounted
        if (mounted) {
          context.read<AuthBloc>().add(
            AuthLoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Extra small screen detection

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (state is AuthFailure) {
            // Customize error message based on error code
            String errorMessage = state.message;
            Color backgroundColor = Colors.red;

            // Handle specific error codes
            if (state.code == 'INVALID_CREDENTIALS') {
              errorMessage =
                  'Incorrect username or password. Please try again.';
            } else if (state.code == 'ACCOUNT_LOCKED') {
              errorMessage =
                  'Your account has been locked due to too many failed attempts. Please try again later.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: backgroundColor,
                duration: const Duration(seconds: 4),
                action:
                    state.code == 'INVALID_CREDENTIALS'
                        ? SnackBarAction(
                          label: 'Forgot Password?',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                        )
                        : null,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Container(
                      width: isSmallScreen ? 80 : 100,
                      height: isSmallScreen ? 80 : 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(100),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.thermostat,
                        size: isSmallScreen ? 48 : 60,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // App Name
                    Text(
                      'EnviroSense',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: isSmallScreen ? 24 : null,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),

                    // App Description
                    Text(
                      'Environmental Monitoring',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: isSmallScreen ? 14 : null,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 32 : 48),

                    // Username Field
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remember Me & Forgot Password - Responsive layout
                    isSmallScreen
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Remember Me
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Remember Me',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember Me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Remember Me'),
                              ],
                            ),

                            // Forgot Password
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ],
                        ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Login Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          child:
                              state is AuthLoading
                                  ? SizedBox(
                                    height: isSmallScreen ? 20 : 24,
                                    width: isSmallScreen ? 20 : 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: isSmallScreen ? 2 : 3,
                                    ),
                                  )
                                  : Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 16,
                            ),
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
