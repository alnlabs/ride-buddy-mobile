import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final needsName =
          await ref.read(authStateProvider.notifier).requestOtp(_phone.text.trim());
      if (!mounted) return;
      final q = StringBuffer('phone=${Uri.encodeComponent(_phone.text.trim())}');
      if (needsName) q.write('&needsName=1');
      context.go('/otp?$q');
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      FadeInUp(
                        child: Column(
                          children: [
                            Image.asset('assets/logos/app_icon.png', height: 108),
                            const SizedBox(height: 16),
                            const BrandWordmark(fontSize: 38, center: true),
                            const SizedBox(height: 10),
                            Text(
                              'Employee carpool made simple',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.inkMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      FadeInUp(
                        delay: const Duration(milliseconds: 140),
                        child: SoftPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign in',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'We’ll send a one-time code to your phone',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                  hintText: '9876543210',
                                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                ErrorBanner(_error!),
                              ],
                              const SizedBox(height: 18),
                              PrimaryButton(
                                label: 'Send OTP',
                                loading: _loading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 240),
                        child: Text(
                          'By continuing you agree to use Ride Buddy for office commuting.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
