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
      final response = await authRepository.login(
        username: event.username,
        password: event.password,
      );

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        emit(AuthFailure(response['message'] ?? 'Login failed'));
        return;
      }

      final token = response['access_token'];
      if (token == null) {
        emit(
          const AuthFailure(
            'Invalid response from server. No access token received.',
          ),
        );
        return;
      }

      try {
        // Get user profile
        final userProfile = await authRepository.getUserProfile();

        // Check if there was an error in the user profile response
        if (userProfile.containsKey('error') && userProfile['error'] == true) {
          // If we can't get the profile but have a token, still consider it a success
          AppLogger.w('Failed to get user profile: ${userProfile['message']}');
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
          final user = User.fromJson(userProfile);
          emit(AuthLoginSuccess(token: token, user: user));
        } catch (parseError) {
          // If we can't parse the user profile but have a token, still consider it a success
          AppLogger.e('Error parsing user profile: $parseError', parseError);
          AppLogger.e('User profile data: $userProfile');
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
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Connection error: ${e.toString()}'));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.forgotPassword(email: event.email);

      emit(
        AuthForgotPasswordSuccess(
          response['message'] ?? 'Password reset email sent',
        ),
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
        email: event.email,
      );

      emit(
        AuthResetPasswordSuccess(
          response['message'] ?? 'Password reset successful',
        ),
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await authRepository.clearToken();
      emit(const AuthUnauthenticated());
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthGetUserProfileRequested(
    AuthGetUserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final userProfile = await authRepository.getUserProfile();

      // Check if there was an error in the response
      if (userProfile.containsKey('error') && userProfile['error'] == true) {
        emit(
          AuthFailure(userProfile['message'] ?? 'Failed to get user profile'),
        );
        return;
      }

      try {
        final user = User.fromJson(userProfile);
        emit(AuthAuthenticated(user));
      } catch (parseError) {
        // If we can't parse the user profile, log the error and emit a failure
        AppLogger.e('Error parsing user profile: $parseError', parseError);
        AppLogger.e('User profile data: $userProfile');
        emit(AuthFailure('Error parsing user profile: $parseError'));
      }
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthUpdateUserProfileRequested(
    AuthUpdateUserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.updateUserProfile(
        username: event.username,
        email: event.email,
      );

      // Check if there was an error in the response
      if (response.containsKey('error') && response['error'] == true) {
        emit(AuthFailure(response['message'] ?? 'Failed to update profile'));
        return;
      }

      try {
        final user = User.fromJson(response);
        emit(
          AuthProfileUpdateSuccess(
            user: user,
            message: 'Profile updated successfully',
          ),
        );
      } catch (parseError) {
        AppLogger.e(
          'Error parsing updated user profile: $parseError',
          parseError,
        );
        AppLogger.e('User profile data: $response');
        emit(AuthFailure('Error updating profile: $parseError'));
      }
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
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
