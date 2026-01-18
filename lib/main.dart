import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/now_playing/now_playing_screen.dart';
import 'features/mini_player/mini_player_bar.dart';
import 'features/now_playing/components/component_registry.dart';
import 'shared/theme/app_theme.dart';
import 'shared/layout/responsive_layout.dart';
import 'core/storage/settings_repository.dart';

void main() {
  // Initialize Now Playing components
  initializeComponents();
  
  runApp(
    const ProviderScope(
      child: MusicrrApp(),
    ),
  );
}

// Providers for theme settings
final themeModeProvider = FutureProvider<String?>((ref) async {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return settingsRepo.getThemeMode();
});

final accentColorProvider = FutureProvider<int?>((ref) async {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return settingsRepo.getAccentColor();
});

class MusicrrApp extends ConsumerWidget {
  const MusicrrApp({super.key});

  ThemeMode _parseThemeMode(String? mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final accentColorAsync = ref.watch(accentColorProvider);
    
    final themeMode = themeModeAsync.when(
      data: (mode) => _parseThemeMode(mode),
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );
    
    final accentColor = accentColorAsync.when(
      data: (colorValue) => colorValue != null ? Color(colorValue) : null,
      loading: () => null,
      error: (_, __) => null,
    );

    return MaterialApp.router(
      title: 'Musicrr',
      theme: AppTheme.lightTheme(seedColor: accentColor),
      darkTheme: AppTheme.darkTheme(seedColor: accentColor),
      themeMode: themeMode,
      routerConfig: _router,
      // Accessibility support
      builder: (context, child) {
        return MediaQuery(
          // Respect text scale factor with reasonable limits
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/home',
  errorBuilder: (context, state) {
    // Fallback for any navigation errors
    debugPrint('GoRouter error: ${state.error}');
    return const HomeScreen();
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/now-playing',
          builder: (context, state) => const NowPlayingScreen(),
        ),
      ],
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.library_music_outlined),
        selectedIcon: Icon(Icons.library_music),
        label: 'Library',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: AdaptiveNavigation(
        selectedIndex: _getSelectedIndex(context),
        onDestinationSelected: (index) {
          try {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/library');
                break;
              case 2:
                context.go('/settings');
                break;
            }
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        },
        destinations: destinations,
        child: Column(
          children: [
            Expanded(child: child),
            if (ResponsiveLayout.isMobile(context)) const MiniPlayerBar(),
          ],
        ),
      ),
      // Mini player for tablet/desktop (can be positioned differently)
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? null
          : const MiniPlayerBar(),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      switch (location) {
        case '/home':
          return 0;
        case '/library':
          return 1;
        case '/settings':
          return 2;
        default:
          return 0;
      }
    } catch (e) {
      // Fallback if GoRouterState is not available
      return 0;
    }
  }
}
