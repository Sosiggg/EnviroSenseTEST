import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/custom_text_field.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordRequested(email: _emailController.text.trim()),
      );
    }
  }

  void _showResetTokenDialog() {
    // Use the current context from the build method
    final context = this.context;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Enter Reset Token',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter the token you received:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Check your email inbox and spam folder.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Reset Token',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.vpn_key),
                  hintText: 'Paste your token here',
                ),
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to login page
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tokenController.text.trim().isEmpty) {
                  // Show error if token is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter the reset token'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (mounted) {
                  // Navigate to reset password page with the token and email
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (_) => ResetPasswordPage(
                            token: _tokenController.text.trim(),
                            email: _emailController.text.trim(),
                          ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Extra small screen detection

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthForgotPasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(10),
              ),
            );

            // Show a dialog to enter the reset token after a delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _showResetTokenDialog();
              }
            });
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(10),
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
                    // Icon with container
                    Container(
                      width: isSmallScreen ? 70 : 80,
                      height: isSmallScreen ? 70 : 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: isSmallScreen ? 40 : 45,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Title
                    Text(
                      'Forgot Password',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Subtitle
                    Text(
                      'Enter your email address and we will send you instructions to reset your password',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _resetPassword(),
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
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Reset Password Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed:
                              state is AuthLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child:
                              state is AuthLoading
                                  ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    'Send Reset Instructions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Information text
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You will receive a token to reset your password. For security reasons, the token will expire after 1 hour.',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Back to Login
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_back, size: 16),
                      label: Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
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
