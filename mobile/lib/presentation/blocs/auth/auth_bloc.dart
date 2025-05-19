import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exceptions.dart';
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

      // Get token and ensure it's a string
      var token = response['access_token'];
      if (token == null) {
        emit(
          const AuthFailure(
            'Invalid response from server. No access token received.',
          ),
        );
        return;
      }

      // Convert token to string if it's not already
      token = token.toString();

      try {
        // Get user profile
        final userProfile = await authRepository.getUserProfile();
        final user = User.fromJson(userProfile);

        emit(AuthLoginSuccess(token: token, user: user));
      } catch (profileError) {
        // If we can't get the profile but have a token, still consider it a success
        // but with a warning
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
      final user = User.fromJson(userProfile);
      emit(AuthAuthenticated(user));
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

      final user = User.fromJson(response);

      emit(
        AuthProfileUpdateSuccess(
          user: user,
          message: 'Profile updated successfully',
        ),
      );
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
