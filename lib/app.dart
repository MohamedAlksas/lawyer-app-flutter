import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'i18n/messages.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'services/notification_service.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/cases/cases_screen.dart';
import 'screens/cases/case_detail_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/users/users_screen.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/offline_banner.dart';
import 'widgets/forms/case_form.dart';

class LawyerApp extends ConsumerStatefulWidget {
  const LawyerApp({super.key});

  @override
  ConsumerState<LawyerApp> createState() => _LawyerAppState();
}

class _LawyerAppState extends ConsumerState<LawyerApp> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).init());
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
    final isRtl = locale.languageCode == 'ar';

    return MaterialApp(
      title: 'Law Office',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) {
        final auth = ref.watch(authProvider);
        if (!auth.isInitialized) {
          return const Material(child: Center(child: CircularProgressIndicator()));
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: OfflineBanner(child: _buildShell(context, child!)),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context, Widget child) {
    final s = S.of(context);
    final user = ref.watch(authProvider).user;
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) {
            setState(() => _selectedIndex = i);
            _navigate(i, context);
          },
          destinations: [
            NavigationDestination(icon: const Icon(Icons.dashboard), label: s.dashboard),
            NavigationDestination(icon: const Icon(Icons.people), label: s.clients),
            NavigationDestination(icon: const Icon(Icons.gavel), label: s.cases),
            NavigationDestination(icon: const Icon(Icons.calendar_month), label: s.calendar),
            NavigationDestination(icon: const Icon(Icons.notifications), label: s.notifications),
            if (user?.isAdmin == true) NavigationDestination(icon: const Icon(Icons.manage_accounts), label: s.users),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              setState(() => _selectedIndex = i);
              _navigate(i, context);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.balance, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
            destinations: [
              NavigationRailDestination(icon: const Icon(Icons.dashboard), label: Text(s.dashboard)),
              NavigationRailDestination(icon: const Icon(Icons.people), label: Text(s.clients)),
              NavigationRailDestination(icon: const Icon(Icons.gavel), label: Text(s.cases)),
              NavigationRailDestination(icon: const Icon(Icons.calendar_month), label: Text(s.calendar)),
              NavigationRailDestination(icon: const Icon(Icons.notifications), label: Text(s.notifications)),
              if (user?.isAdmin == true)
                NavigationRailDestination(icon: const Icon(Icons.manage_accounts), label: Text(s.users)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          )),
        ],
      ),
    );
  }

  void _navigate(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/clients');
      case 2: context.go('/cases');
      case 3: context.go('/calendar');
      case 4: context.go('/notifications');
      case 5: context.go('/users');
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
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
                      caseModel: null, // would need to fetch
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
    ],
  );
});
