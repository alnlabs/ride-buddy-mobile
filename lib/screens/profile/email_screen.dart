import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Office email → verified employee badge. Personal/social email optional (no verification yet).
/// Real SMTP is a placeholder — mock code works in local/dev.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _office = TextEditingController();
  final _contact = TextEditingController();
  final _code = TextEditingController(text: '123456');
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _hint;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final p = ref.read(profileProvider).valueOrNull;
    if (p != null) {
      _office.text = p.officeEmail ?? '';
      _contact.text = p.contactEmail ?? '';
      _pending = p.officeEmailStatus == 'pending';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _office.dispose();
    _contact.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(rideRepositoryProvider).updateProfile({
        'contactEmail': _contact.text.trim(),
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal email saved')),
        );
      }
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestOfficeCode() async {
    setState(() {
      _busy = true;
      _error = null;
      _hint = null;
    });
    try {
      final res = await ref.read(rideRepositoryProvider).requestOfficeEmail(_office.text.trim());
      ref.invalidate(profileProvider);
      setState(() {
        _pending = true;
        _hint = res['hint'] as String? ??
            'Email service not wired yet — check logs or use the mock code.';
      });
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOffice() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(rideRepositoryProvider).verifyOfficeEmail(_code.text.trim());
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified employee')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearOffice() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(rideRepositoryProvider).clearOfficeEmail();
      ref.invalidate(profileProvider);
      setState(() {
        _pending = false;
        _office.clear();
        _hint = null;
      });
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final verified = profile?.employeeVerified == true;

    return SkyScaffold(
      appBar: AppBar(title: const Text('Email')),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  'Anyone can use Ride Buddy. Verifying a company email adds a Verified employee mark on your posts. Personal mail (Gmail etc.) is optional and does not grant that mark.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.4),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Office email'),
                const SizedBox(height: 8),
                SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (verified) ...[
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppTheme.brandBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verified employee\n${profile?.officeEmail ?? ''}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _busy ? null : _clearOffice,
                          child: const Text('Remove verification'),
                        ),
                      ] else ...[
                        TextField(
                          controller: _office,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Company email',
                            hintText: 'you@company.com',
                            prefixIcon: Icon(Icons.business_center_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: _pending ? 'Resend code' : 'Send verification code',
                          loading: _busy,
                          onPressed: _requestOfficeCode,
                        ),
                        if (_pending) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Verification code',
                              hintText: '123456',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Verify office email',
                            loading: _busy,
                            onPressed: _verifyOffice,
                          ),
                        ],
                        if (_hint != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _hint!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.brandOrange),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Mail sending is a placeholder — use mock code 123456 in local/dev.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionLabel('Personal / social email'),
                const SizedBox(height: 8),
                SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Optional. Gmail, Outlook, etc. — join and contact only, not for employee verification.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contact,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Personal email',
                          hintText: 'you@gmail.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _busy ? null : _saveContact,
                        child: const Text('Save personal email'),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(_error!),
                ],
              ],
            ),
    );
  }
}
