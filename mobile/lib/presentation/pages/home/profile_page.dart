import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/custom_text_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  User? _user;

  @override
  void initState() {
    super.initState();

    // Clear any existing user data
    _resetUserData();

    // Get fresh user profile data
    context.read<AuthBloc>().add(const AuthGetUserProfileRequested());

    AppLogger.i(
      'ProfilePage: Initialized and requested fresh user profile data',
    );
  }

  // Helper method to reset all user data
  void _resetUserData() {
    setState(() {
      _user = null;
      _usernameController.clear();
      _emailController.clear();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });

    AppLogger.i('ProfilePage: User data reset');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      // Check if username or email has changed
      if (_usernameController.text.trim() == _user!.username &&
          _emailController.text.trim() == _user!.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating profile...'),
          duration: Duration(seconds: 1),
        ),
      );

      context.read<AuthBloc>().add(
        AuthUpdateUserProfileRequested(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  void _changePassword() {
    // Create a separate form key for password validation
    final passwordFormValid = _formKey.currentState!.validate();

    if (passwordFormValid) {
      // Check if new password fields match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if current password is empty
      if (_currentPasswordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if new password is empty
      if (_newPasswordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New password is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changing password...'),
          duration: Duration(seconds: 1),
        ),
      );

      context.read<AuthBloc>().add(
        AuthChangePasswordRequested(
          currentPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Check if this is a different user than before
          if (_user != null && _user!.id != state.user.id) {
            AppLogger.i(
              'ProfilePage: Detected user switch from ID ${_user!.id} to ${state.user.id}',
            );
            // Complete reset for user switch
            _resetUserData();
          }

          // Only update if the user is different or null
          if (_user == null ||
              _user!.id != state.user.id ||
              _user!.username != state.user.username) {
            setState(() {
              _user = state.user;
              _usernameController.text = state.user.username;
              _emailController.text = state.user.email;
            });

            // Log the user data update
            AppLogger.i(
              'ProfilePage: Updated user data for ${state.user.username} (ID: ${state.user.id})',
            );
          }
        } else if (state is AuthLoginSuccess) {
          // When a new login occurs, reset all data
          AppLogger.i('ProfilePage: New login detected, resetting user data');
          _resetUserData();

          // The AuthAuthenticated state will be emitted later with the user data
        } else if (state is AuthProfileUpdateSuccess) {
          setState(() {
            _user = state.user;
            _usernameController.text = state.user.username;
            _emailController.text = state.user.email;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthChangePasswordSuccess) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is AuthUnauthenticated) {
          // Complete reset for logout
          AppLogger.i('ProfilePage: User logged out, resetting all data');
          _resetUserData();
        } else if (state is AuthLoading) {
          // Don't reset data during loading
        } else {
          // For any other state, log it
          AppLogger.d('ProfilePage: Received state: ${state.runtimeType}');
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading && _user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_user == null) {
              return const Center(child: Text('No user data available'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header - Responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Adjust avatar size based on screen width
                        final avatarRadius =
                            constraints.maxWidth < 400 ? 40.0 : 50.0;
                        final iconSize =
                            constraints.maxWidth < 400 ? 40.0 : 50.0;
                        final textStyle =
                            constraints.maxWidth < 400
                                ? Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)
                                : Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold);

                        return Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  Icons.person,
                                  size: iconSize,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user!.username,
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _user!.email,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Profile Information
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username Field
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Update Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            state is AuthLoading
                                ? const CircularProgressIndicator()
                                : const Text('Update Profile'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Change Password
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Password Field
                    CustomTextField(
                      controller: _currentPasswordController,
                      labelText: 'Current Password',
                      prefixIcon: Icons.lock,
                      obscureText: _obscureCurrentPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        // Only validate if any password field has content
                        if (_newPasswordController.text.isNotEmpty ||
                            _confirmPasswordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // New Password Field
                    CustomTextField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureNewPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        // Only validate if any password field has content
                        if (_currentPasswordController.text.isNotEmpty ||
                            _confirmPasswordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        // Only validate if new password field has content
                        if (_newPasswordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            state is AuthLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            state is AuthLoading
                                ? const CircularProgressIndicator()
                                : const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
