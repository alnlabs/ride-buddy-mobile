import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/theme/app_theme.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

class NetworkBanner extends ConsumerWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectivityProvider);
    final offline = async.maybeWhen(
      data: (r) => r.every((e) => e == ConnectivityResult.none),
      orElse: () => false,
    );
    if (!offline) return const SizedBox.shrink();
    return Material(
      color: AppTheme.brandOrange,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'No connection — showing cached data where available',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
