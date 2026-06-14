import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'i18n/messages.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/cases/cases_screen.dart';
import 'screens/cases/case_detail_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/common/document_preview_screen.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/offline_banner.dart';
import 'widgets/forms/case_form.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Version Trigger: 2026-06-13-21-45
class LawyerApp extends ConsumerStatefulWidget {
  const LawyerApp({super.key});

  @override
  ConsumerState<LawyerApp> createState() => _LawyerAppState();
}

class _LawyerAppState extends ConsumerState<LawyerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).init();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) UpdateService().checkForUpdate(context);
      });
    });
    NotificationService().listenToMessages(
      onMessage: (title, body, data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$title\n$body'),
            duration: const Duration(seconds: 4),
          ));
        }
      },
      onLaunch: (title, body, data) {
        if (data['type'] == 'session_reminder' || data['type'] == 'limitation_alert') {
          final caseId = data['caseId'];
          if (caseId != null && caseId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/cases/$caseId');
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final auth = ref.watch(authProvider);
    final router = ref.watch(routerProvider);

    if (!auth.isInitialized) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: const Center(child: CircularProgressIndicator()),
      );
    }

    return MaterialApp.router(
      title: 'Law Office v2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      key: navigatorKey,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (!auth.isInitialized) return null;
      if (!auth.isAuthenticated && state.matchedLocation != '/login') return '/login';
      if (auth.isAuthenticated && state.matchedLocation == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/clients', builder: (_, __) => const ClientsScreen()),
          GoRoute(
            path: '/cases',
            builder: (_, __) => const CasesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => Scaffold(
                  appBar: AppBar(),
                  body: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    builder: (_, ctrl) => CaseForm(scrollCtrl: ctrl),
                  ),
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => CaseDetailScreen(caseId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => Scaffold(
                      appBar: AppBar(),
                      body: DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        maxChildSize: 0.95,
                        builder: (_, ctrl) => CaseForm(
                          caseModel: null,
                          scrollCtrl: ctrl,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          GoRoute(
            path: '/preview',
            builder: (_, state) => DocumentPreviewScreen(
              url: state.uri.queryParameters['url'] ?? '',
              title: state.uri.queryParameters['title'] ?? 'Document',
            ),
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final user = ref.watch(authProvider).user;
    final isMobile = ResponsiveLayout.isMobile(context);
    final location = GoRouterState.of(context).matchedLocation;

    final navItems = [
      _NavItem(Icons.insights_outlined, 'Executive', '/dashboard'),
      _NavItem(Icons.people_outline, s.clients, '/clients'),
      _NavItem(Icons.gavel_outlined, s.cases, '/cases'),
      _NavItem(Icons.calendar_today_outlined, s.calendar, '/calendar'),
      _NavItem(Icons.notifications_outlined, s.notifications, '/notifications'),
      _NavItem(Icons.settings_outlined, s.settings, '/settings'),
      if (user?.isAdmin == true)
        _NavItem(Icons.admin_panel_settings_outlined, s.users, '/users'),
    ];

    final selectedIndex = navItems.indexWhere((n) => location.startsWith(n.path));

    final shell = isMobile
        ? Scaffold(
            body: child,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: NavigationBar(
                backgroundColor: AppColors.glassBackground,
                elevation: 0,
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onDestinationSelected: (i) => context.go(navItems[i].path),
                destinations: navItems.map((n) => NavigationDestination(
                  icon: Icon(n.icon),
                  label: n.label,
                )).toList(),
              ),
            ),
          )
        : Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                  onDestinationSelected: (i) => context.go(navItems[i].path),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Icon(Icons.balance, size: 40, color: AppColors.primary),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: IconButton(
                          icon: const Icon(Icons.logout_outlined, color: AppColors.error),
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                        ),
                      ),
                    ),
                  ),
                  destinations: navItems.map((n) => NavigationRailDestination(
                    icon: Icon(n.icon),
                    label: Text(n.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: child,
                )),
              ],
            ),
          );

    return Directionality(
      textDirection: ref.watch(localeProvider).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: OfflineBanner(child: shell),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.label, this.path);
}
