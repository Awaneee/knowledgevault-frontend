import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Canvas with soft, out-of-focus colour glows behind [child]: sage mist in
/// light mode, pink/violet haze with faint flowing lines in dark mode.
///
/// Glows are radial gradients rather than blur filters so they stay cheap to
/// paint on every platform, including the web.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child, this.intensity = 1});

  final Widget child;

  /// 0..1 — how strong the glows are. Lower it on dense screens.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glows = isDark ? AppColors.darkGlows : AppColors.lightGlows;
    final a = (isDark ? 0.55 : 0.85) * intensity;

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlowPainter(glows: glows, alpha: a, isDark: isDark),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.glows,
    required this.alpha,
    required this.isDark,
  });

  final List<Color> glows;
  final double alpha;
  final bool isDark;

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = math.max(w, 420.0);
    _blob(canvas, Offset(w * 0.15, -r * 0.12), r * 0.75, glows[0]);
    _blob(canvas, Offset(w * 0.95, r * 0.05), r * 0.6, glows[1]);
    _blob(canvas, Offset(w * 0.5, size.height * 0.95), r * 0.7, glows[2]);

    if (isDark) {
      // Faint flowing ribbons, like light catching silk.
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.05);
      for (var i = 0; i < 3; i++) {
        final dy = size.height * (0.18 + i * 0.22);
        final path = Path()
          ..moveTo(-40, dy)
          ..cubicTo(w * 0.3, dy - 140, w * 0.6, dy + 160, w + 40, dy - 30);
        canvas.drawPath(path, line);
      }
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.alpha != alpha || old.isDark != isDark || old.glows != glows;
}

/// The app's "AI" mark: a luminous gradient orb holding a sparkle.
class SparkleOrb extends StatelessWidget {
  const SparkleOrb({super.key, this.size = 56, this.icon = Icons.auto_awesome});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.aiGradient(Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [Colors.white.withValues(alpha: 0.95), colors[0], colors[1]],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.45),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.02,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.44),
    );
  }
}

/// A large, soft, blurred colour orb — the centrepiece of empty states.
class HaloOrb extends StatelessWidget {
  const HaloOrb({super.key, this.size = 220, this.child});

  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.aiGradient(Theme.of(context).brightness);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors[1].withValues(alpha: 0.9),
              colors[0].withValues(alpha: 0.55),
              colors[0].withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Two-line headline: a light first line over a heavier second line.
class TwoToneTitle extends StatelessWidget {
  const TwoToneTitle(
    this.light,
    this.strong, {
    super.key,
    this.textAlign = TextAlign.start,
    this.size = 32,
  });

  final String light;
  final String strong;
  final TextAlign textAlign;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = TextStyle(
      fontFamily: AppColors.fontFamily,
      fontSize: size,
      height: 1.15,
      letterSpacing: -size * 0.03,
      color: cs.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$light\n',
            style: base.copyWith(
              fontWeight: FontWeight.w300,
              color: cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
          TextSpan(
            text: strong,
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// "Title ........ See all" row above a section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: tt.titleMedium),
          const Spacer(),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// A soft gradient "folder" card: icon chip, title and a small caption.
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    required this.pastel,
    required this.icon,
    required this.title,
    required this.caption,
    this.onTap,
  });

  final Pastel pastel;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: '$title, $caption',
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        // Clip the corner sheen to the card's rounded shape.
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: pastel.gradient,
            borderRadius: BorderRadius.circular(26),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // A light sheen in the corner gives the frosted-glass depth.
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: AppColors.onPastel),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          color: AppColors.onPastel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.onPastel.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded square holding an icon on a tinted background.
class IconChip extends StatelessWidget {
  const IconChip(this.icon, {super.key, this.pastel, this.size = 40});

  final IconData icon;
  final Pastel? pastel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: pastel?.gradient,
        color: pastel == null ? cs.primaryContainer : null,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: pastel != null ? AppColors.onPastel : cs.onPrimaryContainer,
      ),
    );
  }
}
