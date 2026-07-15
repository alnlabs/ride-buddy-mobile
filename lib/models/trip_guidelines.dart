class TripGuidelines {
  TripGuidelines({
    required this.phase,
    required this.role,
    required this.heading,
    required this.intro,
    required this.common,
    required this.expectations,
    required this.conversationHints,
    required this.sharedInterests,
    this.partnerDisplayName,
    this.viewerHasInterests = false,
    this.partnerHasInterests = false,
  });

  final String phase;
  final String role;
  final String heading;
  final String intro;
  final List<GuidelineItem> common;
  final List<GuidelineItem> expectations;
  final List<ConversationHint> conversationHints;
  final List<String> sharedInterests;
  final String? partnerDisplayName;
  final bool viewerHasInterests;
  final bool partnerHasInterests;

  bool get isHost => role == 'host';
  bool get isDuringTrip => phase == 'during';
  bool get hasSharedInterests => sharedInterests.isNotEmpty;

  factory TripGuidelines.fromJson(Map<String, dynamic> j) => TripGuidelines(
        phase: j['phase'] as String? ?? 'before',
        role: j['role'] as String? ?? 'co_rider',
        heading: j['heading'] as String? ?? 'Guidelines',
        intro: j['intro'] as String? ?? '',
        common: (j['common'] as List<dynamic>?)
                ?.map((e) => GuidelineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        expectations: (j['expectations'] as List<dynamic>?)
                ?.map((e) => GuidelineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        conversationHints: (j['conversationHints'] as List<dynamic>?)
                ?.map((e) => ConversationHint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        sharedInterests: (j['sharedInterests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        partnerDisplayName: j['partnerDisplayName'] as String?,
        viewerHasInterests: j['viewerHasInterests'] as bool? ?? false,
        partnerHasInterests: j['partnerHasInterests'] as bool? ?? false,
      );
}

class GuidelineItem {
  const GuidelineItem({required this.title, required this.body});

  final String title;
  final String body;

  factory GuidelineItem.fromJson(Map<String, dynamic> j) => GuidelineItem(
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
      );
}

class ConversationHint {
  const ConversationHint({required this.interest, required this.suggestion});

  final String interest;
  final String suggestion;

  factory ConversationHint.fromJson(Map<String, dynamic> j) => ConversationHint(
        interest: j['interest'] as String? ?? '',
        suggestion: j['suggestion'] as String? ?? '',
      );
}
