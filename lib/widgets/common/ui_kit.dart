import 'package:flutter/material.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// Soft sky wash used behind most screens.
class SkyScaffold extends StatelessWidget {
  const SkyScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.extendBodyBehindAppBar = false,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.skyTop,
              AppTheme.skyMid,
              AppTheme.surface,
            ],
            stops: [0, 0.35, 1],
          ),
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 34, this.center = false});

  final double fontSize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Ride',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppTheme.brandBlue,
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
          TextSpan(
            text: 'Buddy',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppTheme.brandOrange,
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
        ],
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
    return text;
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              );

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: backgroundColor == null
          ? null
          : ElevatedButton.styleFrom(backgroundColor: backgroundColor),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.inkMuted,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
    );
  }
}

/// Interactive destination / navigation row (not decorative card chrome).
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.accent = AppTheme.brandBlue,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color accent;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final badge = badgeCount ?? 0;
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (badge > 0) ...[
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.inkMuted.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Material (not DecoratedBox) so nested ListTiles can paint ink/splashes.
    final pad = padding ?? const EdgeInsets.all(16);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppTheme.line),
    );
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppTheme.surfaceElevated,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: pad, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: pad, child: child),
              ),
      ),
    );
  }
}

class StrengthBar extends StatelessWidget {
  const StrengthBar({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final v = (value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Profile strength', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              '$value%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.brandBlue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 8,
            backgroundColor: AppTheme.line,
            color: value >= 70 ? AppTheme.success : AppTheme.brandOrange,
          ),
        ),
      ],
    );
  }
}

class FadeInUp extends StatefulWidget {
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero, this.offset = 18});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween(
    begin: Offset(0, widget.offset / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
    );
  }
}

/// Host-set trip share amount shown to co-riders (and in host summaries).
class FareChip extends StatelessWidget {
  const FareChip({
    super.key,
    required this.pricePerSeat,
    this.compact = false,
    this.emphasize = false,
  });

  final double pricePerSeat;
  final bool compact;
  final bool emphasize;

  String get _amount {
    final v = pricePerSeat;
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Text(
        '₹$_amount / seat · share cost',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.brandOrange,
              fontWeight: FontWeight.w700,
            ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: emphasize ? 14 : 12),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.brandOrange.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppTheme.brandOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹$_amount per seat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.brandOrange,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Share the trip cost · cash to the host',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
