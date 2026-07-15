import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Curated interest tags for commute / workplace icebreakers (max 30 saved).
const _interestGroups = <String, List<String>>{
  'Sports & fitness': [
    'badminton',
    'cricket',
    'football',
    'tennis',
    'table tennis',
    'basketball',
    'volleyball',
    'walking',
    'running',
    'jogging',
    'yoga',
    'gym',
    'cycling',
    'swimming',
    'hiking',
    'trekking',
    'marathon',
    'padel',
    'golf',
    'skating',
  ],
  'Food & hangouts': [
    'coffee',
    'chai',
    'street food',
    'biryani',
    'baking',
    'cooking',
    'vegetarian food',
    'vegan',
    'brunch',
    'fine dining',
    'bakeries',
    'food trucks',
  ],
  'Entertainment': [
    'movies',
    'web series',
    'anime',
    'standup comedy',
    'theatre',
    'music',
    'karaoke',
    'concerts',
    'podcasts',
    'board games',
    'video games',
    'playstation',
    'chess',
    'carrom',
  ],
  'Outdoors & travel': [
    'travel',
    'road trips',
    'weekends away',
    'camping',
    'beaches',
    'hills',
    'wildlife',
    'photography',
    'drone photography',
    'stargazing',
  ],
  'Tech & career': [
    'coding',
    'AI / ML',
    'startups',
    'product',
    'design',
    'side projects',
    'open source',
    'hackathons',
    'books',
    'self growth',
    'public speaking',
    'mentoring',
  ],
  'Creative & hobbies': [
    'drawing',
    'painting',
    'craft',
    'writing',
    'blogging',
    'guitar',
    'singing',
    'dance',
    'gardening',
    'DIY',
    'fashion',
    'interior design',
  ],
  'Cars & gadgets': [
    'cars',
    'bikes',
    'EV',
    'gadgets',
    'smart home',
    'motorsports',
  ],
  'Lifestyle': [
    'pets',
    'dogs',
    'cats',
    'meditation',
    'spirituality',
    'volunteering',
    'languages',
    'investing',
    'crypto',
    'parenting',
    'fitness tracking',
    'minimalism',
  ],
};

List<String> get _allSuggested =>
    _interestGroups.values.expand((e) => e).toList(growable: false);

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final Set<String> _selected = {};
  final List<String> _top = [];
  final _custom = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(profileProvider).valueOrNull;
      if (p != null) {
        setState(() {
          _selected.addAll(p.interests);
          _top
            ..clear()
            ..addAll(p.topInterests.where((t) => p.interests.contains(t)).take(5));
          if (_top.isEmpty) {
            _top.addAll(p.interests.take(5));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String tag, bool on) {
    setState(() {
      if (on) {
        if (_selected.length >= 30) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 30 interests')),
          );
          return;
        }
        _selected.add(tag);
        if (_top.length < 5 && !_top.contains(tag)) {
          _top.add(tag);
        }
      } else {
        _selected.remove(tag);
        _top.remove(tag);
      }
    });
  }

  void _toggleTop(String tag) {
    if (!_selected.contains(tag)) return;
    setState(() {
      if (_top.contains(tag)) {
        _top.remove(tag);
      } else if (_top.length < 5) {
        _top.add(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Top 5 full — remove one first')),
        );
      }
    });
  }

  void _addCustom() {
    final tag = _custom.text.trim().toLowerCase();
    if (tag.length < 2) return;
    if (tag.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep interests under 40 characters')),
      );
      return;
    }
    _toggle(tag, true);
    _custom.clear();
  }

  Future<void> _save() async {
    if (_selected.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least 5 interests')),
      );
      return;
    }
    final top = List<String>.from(_top.where(_selected.contains).take(5));
    if (top.isEmpty) {
      top.addAll(_selected.take(5));
    }
    setState(() => _saving = true);
    try {
      await ref.read(rideRepositoryProvider).updateInterests(
            _selected.toList(),
            topTags: top,
          );
      ref.invalidate(profileProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _matches(String tag) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return tag.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final customSelected = _selected.where((t) => !_allSuggested.contains(t)).toList()..sort();

    return SkyScaffold(
      appBar: AppBar(title: const Text('Interests')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Selected ${_selected.length} · pick at least 5 (max 30). Star up to 5 to show on your posts.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SoftPanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On posts (${_top.length}/5)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.brandBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap ★ on a pick below to feature it. Order = post order.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (_top.isEmpty)
                      Text('None yet — star your favourites', style: Theme.of(context).textTheme.bodySmall)
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _top.length; i++)
                            InputChip(
                              avatar: CircleAvatar(
                                backgroundColor: AppTheme.brandBlue,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                ),
                              ),
                              label: Text(_top[i]),
                              onDeleted: () => setState(() => _top.removeAt(i)),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search interests…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                if (_selected.isNotEmpty) ...[
                  Text('Your picks', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.brandBlue)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selected.map((t) {
                      final featured = _top.contains(t);
                      return InputChip(
                        avatar: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: Icon(
                            featured ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: featured ? AppTheme.brandOrange : AppTheme.inkMuted,
                          ),
                          onPressed: () => _toggleTop(t),
                        ),
                        label: Text(t),
                        onDeleted: () => _toggle(t, false),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap ★ to feature up to 5 interests on your posts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                ],
                for (final entry in _interestGroups.entries) ...[
                  Builder(builder: (context) {
                    final tags = entry.value.where(_matches).toList();
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((t) {
                              final on = _selected.contains(t);
                              final featured = _top.contains(t);
                              return FilterChip(
                                avatar: on
                                    ? Icon(
                                        featured ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 18,
                                        color: featured ? AppTheme.brandOrange : AppTheme.inkMuted,
                                      )
                                    : null,
                                label: Text(t),
                                selected: on,
                                onSelected: (v) {
                                  if (v) {
                                    _toggle(t, true);
                                  } else if (featured) {
                                    _toggleTop(t);
                                  } else {
                                    _toggle(t, false);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (customSelected.isNotEmpty && _query.isEmpty) ...[
                  Text('Custom', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customSelected.map((t) {
                      return FilterChip(
                        label: Text(t),
                        selected: true,
                        onSelected: (_) => _toggle(t, false),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add your own', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _custom,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addCustom(),
                              decoration: const InputDecoration(
                                hintText: 'e.g. bird watching',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _addCustom,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: PrimaryButton(
              label: _saving ? 'Saving…' : 'Save interests',
              loading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
