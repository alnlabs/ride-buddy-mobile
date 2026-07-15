import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.needsDisplayName = false,
  });

  final String phone;
  final bool needsDisplayName;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otp = TextEditingController(text: '123456');
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final name = _name.text.trim();
    if (widget.needsDisplayName && name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).verifyOtp(
            widget.phone,
            _otp.text.trim(),
            displayName: name.isEmpty ? null : name,
          );
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(
        title: const Text('Verify'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            FadeInUp(
              child: Text(
                'Enter the code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 80),
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                  children: [
                    const TextSpan(text: 'Sent to '),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 140),
              child: SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      textInputAction: widget.needsDisplayName
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _verify(),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 8,
                            fontWeight: FontWeight.w700,
                          ),
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        hintText: '••••••',
                      ),
                    ),
                    if (widget.needsDisplayName) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _verify(),
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          hintText: 'How coworkers should know you',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Dev tip: mock OTP is 123456',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(_error!),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Continue',
                      loading: _loading,
                      onPressed: _verify,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
