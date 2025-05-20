import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/sensor_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/sensor_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/sensor/sensor_bloc.dart';
import 'presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize repositories
  final AuthRepository authRepository = AuthRepositoryImpl();
  final SensorRepository sensorRepository = SensorRepositoryImpl();

  // Initialize theme provider
  final themeProvider = ThemeProvider(sharedPreferences);
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        RepositoryProvider<AuthRepository>(create: (context) => authRepository),
        RepositoryProvider<SensorRepository>(
          create: (context) => sensorRepository,
        ),
        BlocProvider<AuthBloc>(
          create:
              (context) =>
                  AuthBloc(authRepository: context.read<AuthRepository>()),
        ),
        BlocProvider<SensorBloc>(
          create:
              (context) => SensorBloc(
                sensorRepository: context.read<SensorRepository>(),
              ),
        ),
      ],
      child: const EnviroSenseApp(),
    ),
  );
}

class EnviroSenseApp extends StatelessWidget {
  const EnviroSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'EnviroSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Wrap the app in a FocusScope to ensure keyboard events are properly handled
      builder: (context, child) {
        return GestureDetector(
          // Add this to ensure tapping outside of text fields dismisses the keyboard
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          // Wrap in a FocusScope to ensure keyboard events are properly handled
          child: Focus(
            // This ensures the app can receive keyboard events properly
            autofocus: true,
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
