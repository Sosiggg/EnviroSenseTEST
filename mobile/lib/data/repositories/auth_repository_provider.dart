import '../../domain/repositories/auth_repository.dart';
import 'auth_repository_impl.dart';

/// Factory for creating AuthRepository instances.
/// 
/// This class provides a centralized way to create AuthRepository instances,
/// making it easier to switch implementations if needed.
class AuthRepositoryProvider {
  /// Creates and returns an instance of AuthRepository.
  /// 
  /// Currently returns an instance of AuthRepositoryImpl.
  static AuthRepository getRepository() {
    return AuthRepositoryImpl();
  }
}
