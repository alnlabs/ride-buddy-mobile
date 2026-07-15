import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Job role + company — always shown on ride / need posts.
class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends ConsumerState<WorkScreen> {
  final _role = TextEditingController();
  final _company = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final p = ref.read(profileProvider).valueOrNull;
    if (p != null) {
      _role.text = p.jobRole ?? '';
      _company.text = p.company ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _role.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final role = _role.text.trim();
    final company = _company.text.trim();
    if (role.isEmpty || company.isEmpty) {
      setState(() => _error = 'Add both your role and company — they appear on every post');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(rideRepositoryProvider).updateProfile({
        'jobRole': role,
        'company': company,
      });
      ref.invalidate(profileProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Role & company')),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  'Shown on every ride or need you post, so others know who they’re riding with.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
                ),
                const SizedBox(height: 18),
                SoftPanel(
                  child: Column(
                    children: [
                      TextField(
                        controller: _role,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          hintText: 'e.g. Product Designer',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _company,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          hintText: 'e.g. Acme Labs',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(_error!),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Save',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
