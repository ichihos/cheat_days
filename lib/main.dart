import 'package:cheat_days/core/theme/app_theme.dart';
import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/presentation/home_screen.dart';
import 'package:cheat_days/features/home/presentation/yesterday_check_dialog.dart';
import 'package:cheat_days/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cheat_days/features/records/presentation/records_screen.dart';
import 'package:cheat_days/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cheat_days/features/shopping_list/presentation/shopping_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const ProviderScope(child: MessieApp()));
}

class MessieApp extends ConsumerWidget {
  const MessieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Messie',
      theme: AppTheme.theme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Ensure profile exists
          ref.read(userRepositoryProvider).createProfileIfAbsent(user);
          return const OnboardingChecker();
        } else {
          // Auto sign-in anonymously
          ref.read(authRepositoryProvider).signInAnonymously();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

/// Check if onboarding is complete before showing main scaffold
class OnboardingChecker extends ConsumerWidget {
  const OnboardingChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (!settings.isOnboardingComplete) {
          return OnboardingScreen(
            onComplete: () {
              // Force rebuild by invalidating the provider
              ref.invalidate(userSettingsProvider);
            },
          );
        }
        return const MainScaffoldWithCheck();
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        // If settings don't exist yet, show onboarding
        return OnboardingScreen(
          onComplete: () => ref.invalidate(userSettingsProvider),
        );
      },
    );
  }
}

/// Main scaffold that also checks for yesterday's meal on first load
class MainScaffoldWithCheck extends ConsumerStatefulWidget {
  const MainScaffoldWithCheck({super.key});

  @override
  ConsumerState<MainScaffoldWithCheck> createState() =>
      _MainScaffoldWithCheckState();
}

class _MainScaffoldWithCheckState extends ConsumerState<MainScaffoldWithCheck> {
  bool _hasCheckedYesterday = false;

  @override
  void initState() {
    super.initState();
    // Schedule the check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkYesterdayMeal();
    });
  }

  Future<void> _checkYesterdayMeal() async {
    if (_hasCheckedYesterday) return;
    _hasCheckedYesterday = true;

    final shouldShow = await shouldShowYesterdayCheck(ref);
    if (shouldShow && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const YesterdayCheckDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScaffold();
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ShoppingListScreen(),
    const RecordsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: '献立'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: '買物'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '記録'),
        ],
      ),
    );
  }
}
