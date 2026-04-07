import 'package:firebase_core/firebase_core.dart';
import 'package:vayu/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import UI screens
import 'package:vayu/presentation/dashboard_screen.dart';
import 'package:vayu/presentation/map_routes_screen.dart';
import 'package:vayu/presentation/netra_vision_screen.dart';
import 'package:vayu/presentation/ai_coach_screen.dart';
import 'package:vayu/presentation/auth_screen.dart';
import 'package:vayu/presentation/profile_screen.dart';
import 'package:vayu/presentation/simulation_screen.dart';
import 'package:vayu/presentation/insights_screen.dart';
import 'package:vayu/presentation/questionnaire_screen.dart';

// Import Providers
import 'package:vayu/providers/auth/auth_provider.dart';
import 'package:vayu/providers/storage/storage_provider.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';

void main() async {
  print('🚀 VAYU App Starting...');
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VayuApp(),
    ),
  );
}

// Router configuration protected by Auth State
final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final healthProfileAsync = ref.watch(healthProfileProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      if (authStateAsync.isLoading || healthProfileAsync.isLoading) return null;

      final isAuth = authStateAsync.valueOrNull != null;
      final isLoggingIn = state.uri.toString() == '/auth';
      final isQuestionnaire = state.uri.toString() == '/questionnaire';

      if (!isAuth && !isLoggingIn) return '/auth';
      if (isAuth && isLoggingIn) return '/';

      // Redirect to questionnaire if profile is incomplete (checking weight as proxy for setup)
      if (isAuth && !isQuestionnaire && healthProfileAsync.valueOrNull?.weight == null) {
        return '/questionnaire';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MapRoutesScreen()),
      GoRoute(path: '/vision', builder: (context, state) => const NetraVisionScreen()),
      GoRoute(path: '/coach', builder: (context, state) => const AiCoachScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/simulation', builder: (context, state) => const SimulationScreen()),
      GoRoute(path: '/insights', builder: (context, state) => const InsightsScreen()),
      GoRoute(path: '/questionnaire', builder: (context, state) => const QuestionnaireScreen()),
    ],
  );
});

class VayuApp extends ConsumerWidget {
  const VayuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'VAYU',
      themeMode: ThemeMode.light,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3CD3AD)),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontFamily: 'Inter'),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
