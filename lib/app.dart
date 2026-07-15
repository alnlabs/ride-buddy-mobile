import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/router/app_router.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/network_banner.dart';

class RideBuddyApp extends ConsumerStatefulWidget {
  const RideBuddyApp({super.key});

  @override
  ConsumerState<RideBuddyApp> createState() => _RideBuddyAppState();
}

class _RideBuddyAppState extends ConsumerState<RideBuddyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.ensurePermissionOnStartup();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ride Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          const NetworkBanner(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
