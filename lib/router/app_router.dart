import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/screens/auth/login_screen.dart';
import 'package:ridebuddy/screens/auth/otp_screen.dart';
import 'package:ridebuddy/screens/booking/my_trips_screen.dart';
import 'package:ridebuddy/screens/home/home_shell.dart';
import 'package:ridebuddy/screens/profile/email_screen.dart';
import 'package:ridebuddy/screens/profile/interests_screen.dart';
import 'package:ridebuddy/screens/profile/places_screen.dart';
import 'package:ridebuddy/screens/profile/profile_screen.dart';
import 'package:ridebuddy/screens/profile/work_screen.dart';
import 'package:ridebuddy/screens/ride/need_detail_screen.dart';
import 'package:ridebuddy/screens/ride/needs_inbox_screen.dart';
import 'package:ridebuddy/screens/ride/post_need_screen.dart';
import 'package:ridebuddy/screens/ride/post_ride_screen.dart';
import 'package:ridebuddy/screens/ride/ride_detail_screen.dart';
import 'package:ridebuddy/screens/ride/ride_hub_screen.dart';
import 'package:ridebuddy/screens/ride/search_rides_screen.dart';
import 'package:ridebuddy/screens/splash_screen.dart';
import 'package:ridebuddy/screens/vehicle/vehicles_screen.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (auth.initializing) {
        return loc == '/' ? null : '/';
      }

      if (auth.isAuthenticated) {
        if (loc == '/' || loc == '/login' || loc.startsWith('/otp')) return '/home';
        return null;
      }

      if (loc == '/') return '/login';
      if (loc.startsWith('/login') || loc.startsWith('/otp')) return null;
      return '/login';
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final needsName = state.uri.queryParameters['needsName'] == '1';
          return OtpScreen(phone: phone, needsDisplayName: needsName);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const _HomeTab()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ride',
              builder: (_, __) => const RideHubScreen(),
              routes: [
                GoRoute(path: 'search', builder: (_, __) => const SearchRidesScreen()),
                GoRoute(path: 'post', builder: (_, __) => const PostRideScreen()),
                GoRoute(path: 'needs', builder: (_, __) => const NeedsInboxScreen()),
                GoRoute(path: 'needs/new', builder: (_, __) => const PostNeedScreen()),
                GoRoute(
                  path: 'need/:id',
                  builder: (_, state) => NeedDetailScreen(requestId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'detail/:id',
                  builder: (_, state) => RideDetailScreen(
                    rideId: state.pathParameters['id']!,
                    preferComfort: state.uri.queryParameters['preferComfort'] == '1',
                  ),
                ),
                GoRoute(path: 'trips', builder: (_, __) => const MyTripsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/jobs', builder: (_, __) => const _ComingSoon(title: 'Jobs')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/meetups', builder: (_, __) => const _ComingSoon(title: 'Meetups')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'places', builder: (_, __) => const PlacesScreen()),
                GoRoute(path: 'work', builder: (_, __) => const WorkScreen()),
                GoRoute(path: 'email', builder: (_, __) => const EmailScreen()),
                GoRoute(path: 'interests', builder: (_, __) => const InterestsScreen()),
                GoRoute(path: 'vehicles', builder: (_, __) => const VehiclesScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(profileProvider);
    final name = auth.displayName?.trim().isNotEmpty == true ? auth.displayName!.trim() : 'there';

    return SkyScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            FadeInUp(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandWordmark(fontSize: 28),
                        const SizedBox(height: 10),
                        Text(
                          'Hi, $name',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Where are you headed today?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'R',
                        style: const TextStyle(
                          color: AppTheme.brandBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: SoftPanel(
                onTap: () => context.go('/ride'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.directions_car_filled_rounded, color: AppTheme.brandBlue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Open Ride', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Get a seat or offer yours — search, map & trips',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            FadeInUp(
              delay: const Duration(milliseconds: 180),
              child: profile.when(
                data: (p) => SoftPanel(
                  onTap: () => context.go('/profile'),
                  child: StrengthBar(value: p.profileStrength),
                ),
                loading: () => const SoftPanel(child: LinearProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 22),
            FadeInUp(
              delay: const Duration(milliseconds: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Quick links'),
                  const SizedBox(height: 10),
                  ActionRow(
                    icon: Icons.confirmation_number_outlined,
                    title: 'My trips',
                    subtitle: 'Bookings as co-rider',
                    onTap: () => context.go('/ride/trips'),
                  ),
                  const SizedBox(height: 10),
                  ActionRow(
                    icon: Icons.place_outlined,
                    title: 'Home & Office',
                    subtitle: 'Better commute matching',
                    accent: AppTheme.brandOrange,
                    onTap: () => context.go('/profile/places'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    title == 'Jobs' ? Icons.work_outline_rounded : Icons.groups_outlined,
                    size: 34,
                    color: AppTheme.brandBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Coming soon — credits & discovery are next.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
