import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthGetUserProfileRequested>(_onAuthGetUserProfileRequested);
    on<AuthUpdateUserProfileRequested>(_onAuthUpdateUserProfileRequested);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final isLoggedIn = await authRepository.isLoggedIn();

      if (isLoggedIn) {
        final userProfile = await authRepository.getUserProfile();
        final user = User.fromJson(userProfile);
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
      );

      emit(
        AuthRegistrationSuccess(
          response['message'] ?? 'Registration successful',
        ),
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      AppLogger.i('Attempting login for user: ${event.username}');

      final response = await authRepository.login(
        username: event.username,
        password: event.password,
      );

      // Log the response for debugging
      AppLogger.d('Login response: $response');

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        final errorMessage = response['message'] ?? 'Login failed';
        AppLogger.w('Login failed: $errorMessage');
        emit(AuthFailure(errorMessage));
        return;
      }

      // Safely extract the token
      String? token;
      if (response.containsKey('access_token')) {
        token = response['access_token']?.toString();
      }

      if (token == null || token.isEmpty) {
        const errorMessage =
            'Invalid response from server. No access token received.';
        AppLogger.w(errorMessage);
        emit(const AuthFailure(errorMessage));
        return;
      }

      AppLogger.i('Login successful, token received');

      try {
        // Get user profile
        AppLogger.i('Fetching user profile');
        final userProfile = await authRepository.getUserProfile();
        AppLogger.d('User profile response: $userProfile');

        // Check if there was an error in the user profile response
        if (userProfile.containsKey('error') && userProfile['error'] == true) {
          // If we can't get the profile but have a token, still consider it a success
          final errorMessage = userProfile['message'] ?? 'Unknown error';
          AppLogger.w('Failed to get user profile: $errorMessage');
          emit(
            AuthLoginSuccess(
              token: token,
              user: User(
                id: 0,
                username: event.username,
                email: '',
                isActive: true,
              ),
            ),
          );
          return;
        }

        try {
          // Create a fallback user in case parsing fails
          final fallbackUser = User(
            id: 0,
            username: event.username,
            email: userProfile['email'] ?? '',
            isActive: true,
          );

          // Try to parse the user profile
          User user;
          try {
            user = User.fromJson(userProfile);
          } catch (parseError) {
            AppLogger.e('Error parsing user profile: $parseError', parseError);
            AppLogger.e('User profile data: $userProfile');
            user = fallbackUser;
          }

          AppLogger.i('Login and profile fetch successful');
          emit(AuthLoginSuccess(token: token, user: user));
        } catch (parseError) {
          // If we can't parse the user profile but have a token, still consider it a success
          AppLogger.e('Error handling user profile: $parseError', parseError);
          emit(
            AuthLoginSuccess(
              token: token,
              user: User(
                id: 0,
                username: event.username,
                email: '',
                isActive: true,
              ),
            ),
          );
        }
      } catch (profileError) {
        // If we can't get the profile but have a token, still consider it a success
        AppLogger.w('Error fetching user profile: $profileError');
        emit(
          AuthLoginSuccess(
            token: token,
            user: User(
              id: 0,
              username: event.username,
              email: '',
              isActive: true,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      AppLogger.e('API exception during login: ${e.message}', e);
      emit(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected error during login: $e', e);
      emit(AuthFailure('Connection error: ${e.toString()}'));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      AppLogger.i('Requesting password reset for email: ${event.email}');

      final response = await authRepository.forgotPassword(email: event.email);

      AppLogger.d('Forgot password response: $response');

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        final errorMessage = response['message'] ?? 'Failed to reset password';

        // If this is an HTML response that we've already handled in the repository
        if (response.containsKey('raw_response')) {
          // We'll show a success message instead of the HTML error
          AppLogger.i(
            'HTML response detected, showing success message instead',
          );
          emit(
            AuthForgotPasswordSuccess(
              'Password reset request sent. Please check your email for instructions.',
            ),
          );
          return;
        }

        AppLogger.w('Forgot password failed: $errorMessage');
        emit(AuthFailure(errorMessage));
        return;
      }

      // Extract the success message
      final successMessage = response['message'] ?? 'Password reset email sent';
      AppLogger.i('Password reset request successful: $successMessage');

      emit(AuthForgotPasswordSuccess(successMessage));
    } on ApiException catch (e) {
      AppLogger.e('API exception during password reset: ${e.message}', e);
      emit(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected error during password reset: $e', e);
      emit(AuthFailure('Error requesting password reset: ${e.toString()}'));
    }
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      AppLogger.i('Resetting password for email: ${event.email} with token');

      final response = await authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
        email: event.email,
      );

      AppLogger.d('Reset password response: $response');

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        final errorMessage = response['message'] ?? 'Failed to reset password';

        // If this is an HTML response that we've already handled in the repository
        if (response.containsKey('raw_response')) {
          // We'll show a success message instead of the HTML error
          AppLogger.i(
            'HTML response detected, showing success message instead',
          );
          emit(
            AuthResetPasswordSuccess(
              'Password reset successful. Please login with your new password.',
            ),
          );
          return;
        }

        AppLogger.w('Reset password failed: $errorMessage');
        emit(AuthFailure(errorMessage));
        return;
      }

      // Extract the success message
      final successMessage = response['message'] ?? 'Password reset successful';
      AppLogger.i('Password reset successful: $successMessage');

      emit(AuthResetPasswordSuccess(successMessage));
    } on ApiException catch (e) {
      AppLogger.e('API exception during password reset: ${e.message}', e);
      emit(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected error during password reset: $e', e);
      emit(AuthFailure('Error resetting password: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Note: WebSocket disconnection is now handled in the HomePage before this event is dispatched
      // This ensures that the WebSocket is properly disconnected before the token is cleared

      // Clear the token and any cached user data
      await authRepository.clearToken();

      // Clear any cached user data in the API client
      await authRepository.clearUserCache();

      AppLogger.i('User logged out successfully - all user data cleared');

      // Emit unauthenticated state to trigger navigation to login screen
      emit(const AuthUnauthenticated());
    } on ApiException catch (e) {
      AppLogger.e('API exception during logout: ${e.message}', e);
      emit(AuthFailure(e.message));

      // Even if there's an error, still try to clear the token and emit unauthenticated state
      try {
        await authRepository.clearToken();
        await authRepository.clearUserCache();
        emit(const AuthUnauthenticated());
      } catch (clearError) {
        AppLogger.e(
          'Error clearing token after failed logout: $clearError',
          clearError,
        );
      }
    } catch (e) {
      AppLogger.e('Unexpected error during logout: $e', e);
      emit(AuthFailure(e.toString()));

      // Even if there's an error, still try to clear the token and emit unauthenticated state
      try {
        await authRepository.clearToken();
        await authRepository.clearUserCache();
        emit(const AuthUnauthenticated());
      } catch (clearError) {
        AppLogger.e(
          'Error clearing token after failed logout: $clearError',
          clearError,
        );
      }
    }
  }

  Future<void> _onAuthGetUserProfileRequested(
    AuthGetUserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      AppLogger.i('Fetching user profile');
      final userProfile = await authRepository.getUserProfile();
      AppLogger.d('User profile response: $userProfile');

      // Check if there was an error in the response
      if (userProfile.containsKey('error') && userProfile['error'] == true) {
        final errorMessage =
            userProfile['message'] ?? 'Failed to get user profile';
        AppLogger.w('Failed to get user profile: $errorMessage');
        emit(AuthFailure(errorMessage));
        return;
      }

      try {
        // Create a fallback user in case parsing fails
        final fallbackUser = User(
          id: 0,
          username: userProfile['username'] ?? 'User',
          email: userProfile['email'] ?? '',
          isActive: true,
        );

        // Try to parse the user profile
        User user;
        try {
          user = User.fromJson(userProfile);
        } catch (parseError) {
          AppLogger.e('Error parsing user profile: $parseError', parseError);
          AppLogger.e('User profile data: $userProfile');
          user = fallbackUser;
        }

        AppLogger.i('User profile fetched successfully');
        emit(AuthAuthenticated(user));
      } catch (parseError) {
        // If we can't parse the user profile, log the error and emit a failure
        AppLogger.e('Error handling user profile: $parseError', parseError);
        AppLogger.e('User profile data: $userProfile');
        emit(AuthFailure('Error processing user profile: $parseError'));
      }
    } on ApiException catch (e) {
      AppLogger.e('API exception during profile fetch: ${e.message}', e);
      emit(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected error during profile fetch: $e', e);
      emit(AuthFailure('Error fetching profile: ${e.toString()}'));
    }
  }

  Future<void> _onAuthUpdateUserProfileRequested(
    AuthUpdateUserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      AppLogger.i(
        'Updating user profile: username=${event.username}, email=${event.email}',
      );

      final response = await authRepository.updateUserProfile(
        username: event.username,
        email: event.email,
      );

      AppLogger.d('Profile update response: $response');

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        final errorMessage = response['message'] ?? 'Failed to update profile';
        AppLogger.w('Failed to update profile: $errorMessage');
        emit(AuthFailure(errorMessage));
        return;
      }

      try {
        // Create a fallback user in case parsing fails
        final fallbackUser = User(
          id: 0,
          username: event.username ?? 'User',
          email: event.email ?? '',
          isActive: true,
        );

        // Try to parse the user profile
        User user;
        try {
          user = User.fromJson(response);
        } catch (parseError) {
          AppLogger.e(
            'Error parsing updated user profile: $parseError',
            parseError,
          );
          AppLogger.e('User profile data: $response');
          user = fallbackUser;
        }

        AppLogger.i('Profile updated successfully');
        emit(
          AuthProfileUpdateSuccess(
            user: user,
            message: 'Profile updated successfully',
          ),
        );
      } catch (parseError) {
        AppLogger.e('Error handling profile update: $parseError', parseError);
        AppLogger.e('Profile update data: $response');
        emit(AuthFailure('Error processing profile update: $parseError'));
      }
    } on ApiException catch (e) {
      AppLogger.e('API exception during profile update: ${e.message}', e);
      emit(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected error during profile update: $e', e);
      emit(AuthFailure('Error updating profile: ${e.toString()}'));
    }
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      emit(
        AuthChangePasswordSuccess(
          response['message'] ?? 'Password changed successfully',
        ),
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
