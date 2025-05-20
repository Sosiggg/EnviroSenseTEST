import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthRegistrationSuccess extends AuthState {
  final String message;
  
  const AuthRegistrationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthLoginSuccess extends AuthState {
  final String token;
  final User user;
  
  const AuthLoginSuccess({
    required this.token,
    required this.user,
  });
  
  @override
  List<Object?> get props => [token, user];
}

class AuthForgotPasswordSuccess extends AuthState {
  final String message;
  
  const AuthForgotPasswordSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthResetPasswordSuccess extends AuthState {
  final String message;
  
  const AuthResetPasswordSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthProfileUpdateSuccess extends AuthState {
  final User user;
  final String message;
  
  const AuthProfileUpdateSuccess({
    required this.user,
    required this.message,
  });
  
  @override
  List<Object?> get props => [user, message];
}

class AuthChangePasswordSuccess extends AuthState {
  final String message;
  
  const AuthChangePasswordSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  
  const AuthFailure(this.message);
  
  @override
  List<Object?> get props => [message];
}
