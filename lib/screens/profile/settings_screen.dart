import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/services/home_spotlight_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Settings')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const SectionLabel('Home'),
          const SizedBox(height: 10),
          const _TipsSettingsPanel(),
        ],
      ),
    );
  }
}

class _TipsSettingsPanel extends ConsumerStatefulWidget {
  const _TipsSettingsPanel();

  @override
  ConsumerState<_TipsSettingsPanel> createState() => _TipsSettingsPanelState();
}

class _TipsSettingsPanelState extends ConsumerState<_TipsSettingsPanel> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ref.read(homeSpotlightServiceProvider).tipsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text('Show daily tip or quote on Home'),
            subtitle: const Text('Popup once per day, then pinned on Home'),
            value: _enabled ?? true,
            onChanged: _enabled == null
                ? null
                : (v) async {
                    await ref.read(homeSpotlightServiceProvider).setTipsEnabled(v);
                    setState(() => _enabled = v);
                  },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.brandOrange),
            title: const Text('Browse tips & quotes'),
            subtitle: const Text('App, safety, manners, co-riders & quotes'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
            onTap: () => context.push('/tips'),
          ),
        ],
      ),
    );
  }
}
