import 'package:flutter/material.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInUp(
                child: Image.asset('assets/logos/app_icon.png', width: 132, height: 132),
              ),
              const SizedBox(height: 20),
              const FadeInUp(
                delay: Duration(milliseconds: 120),
                child: BrandWordmark(fontSize: 40, center: true),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  'Share the commute. Save the day.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                ),
              ),
              const SizedBox(height: 36),
              FadeInUp(
                delay: const Duration(milliseconds: 320),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
