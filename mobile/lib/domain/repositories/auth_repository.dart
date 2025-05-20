abstract class AuthRepository {
  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  });

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword({required String email});

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String email,
  });

  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile();

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? username,
    String? email,
  });

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get stored token
  Future<String?> getToken();

  /// Store token
  Future<void> saveToken(String token);

  /// Clear token (logout)
  Future<void> clearToken();

  /// Clear any cached user data
  Future<void> clearUserCache();
}
