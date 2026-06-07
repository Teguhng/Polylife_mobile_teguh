import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_mode.dart';
import 'core/notifications/reminder_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/dashboard/views/main_layout.dart';
import 'features/dashboard/views/home_screen.dart';
import 'features/catatan/views/catatan_list_screen.dart';
import 'features/pengumuman/views/pengumuman_list_screen.dart';
import 'features/keuangan/views/keuangan_screen.dart';
import 'features/jadwal/views/jadwal_screen.dart';
import 'features/profile/views/profile_screen.dart';
import 'features/reminder/views/reminder_create_screen.dart';
import 'features/reminder/views/reminder_screen.dart';
import 'features/todo/views/todo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await ReminderNotificationService.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final _RouterRefreshNotifier _routerRefreshNotifier;
  late final ProviderSubscription<bool> _authSubscription;
  late final ProviderSubscription<bool> _authLoadingSubscription;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _routerRefreshNotifier = _RouterRefreshNotifier();
    _router = _buildRouter();

    _authSubscription = ref.listenManual<bool>(authProvider, (previous, next) {
      _routerRefreshNotifier.refresh();
    });
    _authLoadingSubscription = ref.listenManual<bool>(authLoadingProvider, (
      previous,
      next,
    ) {
      _routerRefreshNotifier.refresh();
    });
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _routerRefreshNotifier,
      redirect: (context, state) {
        final isLoading = ref.read(authLoadingProvider);
        final authState = ref.read(authProvider);

        final isGuestAuthRoute = {
          '/login',
          '/register',
          '/forgot-password',
        }.contains(state.matchedLocation);

        if (AppMode.uiOnly) {
          if (isGuestAuthRoute) {
            return '/';
          }
          return null;
        }

        if (isLoading) return null; // wait for check to finish

        if (!authState && !isGuestAuthRoute) {
          return '/login';
        }
        if (authState && isGuestAuthRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reminder',
          builder: (context, state) => const ReminderScreen(),
        ),
        GoRoute(
          path: '/reminder/new',
          builder: (context, state) => const ReminderCreateScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/keuangan',
              builder: (context, state) => const KeuanganScreen(),
            ),
            GoRoute(
              path: '/jadwal',
              builder: (context, state) => const JadwalScreen(),
            ),
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/todo',
              builder: (context, state) => const TodoScreen(),
            ),
            GoRoute(
              path: '/catatan',
              builder: (context, state) => const CatatanListScreen(),
            ),
            GoRoute(
              path: '/pengumuman',
              builder: (context, state) => const PengumumanListScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    _authLoadingSubscription.close();
    _router.dispose();
    _routerRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final themeMode = _themeModeFromPreference(
      ref.watch(userProvider.select((user) => user?.profile?.themePreference)),
    );

    if (isLoading && !AppMode.uiOnly) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'PolyLife',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

ThemeMode _themeModeFromPreference(String? preference) {
  switch ((preference ?? 'system').trim().toLowerCase()) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}
