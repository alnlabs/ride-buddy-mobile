enum SpotlightKind { tip, quote }

class HomeSpotlight {
  const HomeSpotlight({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.category,
    this.author,
    this.ctaLabel,
    this.ctaRoute,
    this.icon = 'lightbulb',
  });

  final String id;
  final SpotlightKind kind;
  final String title;
  final String body;
  /// tip only: app | safety | manners | connect
  final String? category;
  /// quote only
  final String? author;
  final String? ctaLabel;
  final String? ctaRoute;
  final String icon;

  bool get isTip => kind == SpotlightKind.tip;
  bool get isQuote => kind == SpotlightKind.quote;
}
