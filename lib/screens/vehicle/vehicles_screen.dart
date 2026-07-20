import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  return ref.read(rideRepositoryProvider).vehicles();
});

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehiclesProvider);
    return SkyScaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddVehicleSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
        backgroundColor: AppTheme.brandBlue,
        foregroundColor: Colors.white,
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => ErrorView(
          message: ref.read(apiClientProvider).messageFrom(e),
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SoftPanel(
                child: EmptyState(
                  title: 'No vehicles yet',
                  subtitle: 'Add a car or bike to start offering rides',
                  icon: Icons.directions_car_filled_outlined,
                  actionLabel: 'Add vehicle',
                  onAction: () => showAddVehicleSheet(context, ref),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Text(
                  '${list.length} vehicle${list.length == 1 ? '' : 's'} · tap star to set primary',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              final v = list[i - 1];
              return _VehicleCard(
                vehicle: v,
                onPrimary: () async {
                  await ref.read(rideRepositoryProvider).setPrimary(v.id);
                  ref.invalidate(vehiclesProvider);
                },
                onDelete: () => _confirmDelete(context, ref, v),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove vehicle?'),
        content: Text('Remove ${v.displayName} from your garage? You can add it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(rideRepositoryProvider).deleteVehicle(v.id);
    ref.invalidate(vehiclesProvider);
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onPrimary,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onPrimary;
  final VoidCallback onDelete;

  Color get _tint {
    final c = vehicle.color?.toLowerCase().trim() ?? '';
    if (c.contains('white') || c.contains('silver')) return const Color(0xFF94A3B8);
    if (c.contains('black') || c.contains('grey') || c.contains('gray')) return const Color(0xFF334155);
    if (c.contains('red')) return const Color(0xFFDC2626);
    if (c.contains('blue')) return AppTheme.brandBlue;
    if (c.contains('green')) return AppTheme.success;
    if (c.contains('orange') || c.contains('orange')) return AppTheme.brandOrange;
    if (c.contains('yellow')) return const Color(0xFFCA8A04);
    if (c.contains('brown')) return const Color(0xFF92400E);
    return AppTheme.brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.directions_car_filled_rounded, color: _tint, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (v.primary)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.brandOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Primary',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.brandOrange,
                                fontSize: 11,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  v.makeModel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.pin_outlined, label: v.plateMasked),
                    _MetaChip(icon: Icons.event_seat_outlined, label: '${v.seats} seats'),
                    if (v.color != null && v.color!.trim().isNotEmpty)
                      _MetaChip(icon: Icons.palette_outlined, label: v.color!),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: v.primary ? 'Primary vehicle' : 'Make primary',
                onPressed: v.primary ? null : onPrimary,
                icon: Icon(
                  v.primary ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: v.primary ? AppTheme.brandOrange : AppTheme.inkMuted,
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.skyTop,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.inkMuted),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.ink)),
        ],
      ),
    );
  }
}

Future<void> showAddVehicleSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddVehicleSheet(),
  );
}

class _AddVehicleSheet extends ConsumerStatefulWidget {
  const _AddVehicleSheet();

  @override
  ConsumerState<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<_AddVehicleSheet> {
  final _nick = TextEditingController();
  final _make = TextEditingController();
  final _plate = TextEditingController();
  final _seats = TextEditingController(text: '4');
  final _color = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _nick.dispose();
    _make.dispose();
    _plate.dispose();
    _seats.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final makeModel = _make.text.trim();
    final plateNumber = _plate.text.trim().toUpperCase();
    if (makeModel.isEmpty || plateNumber.isEmpty) {
      setState(() => _error = 'Make/model and plate number are required');
      return;
    }
    final seatCount = int.tryParse(_seats.text) ?? 0;
    if (seatCount < 2 || seatCount > 8) {
      setState(() => _error = 'Seats must be between 2 and 8');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(rideRepositoryProvider).createVehicle({
        'nickname': _nick.text.trim(),
        'makeModel': makeModel,
        'plateNumber': plateNumber,
        'seats': seatCount,
        'color': _color.text.trim(),
        'primary': true,
      });
      ref.invalidate(vehiclesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ref.read(apiClientProvider).messageFrom(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add vehicle', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Used when you offer seats · share trip cost in cash for now',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nick,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                hintText: 'e.g. Office Honda',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _make,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Make / model',
                hintText: 'e.g. Honda City',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-\s]'))],
              decoration: const InputDecoration(
                labelText: 'Plate number',
                hintText: 'e.g. TS09AB1234',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seats,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Seats'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _color,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      hintText: 'White',
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(_error!),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Save vehicle',
              loading: _saving,
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
