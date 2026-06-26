import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/feedback/review_service.dart';

const List<String> _lessonOrder = <String>[
  'vowels-01',
  'consonants-01',
  'consonants-02',
  'consonants-03',
  'consonants-04',
  'kudlit-01',
];

class LessonCompletionOverlay extends ConsumerStatefulWidget {
  const LessonCompletionOverlay({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.onNext,
    required this.onPracticeAgain,
    required this.onBack,
  });

  final String lessonId;
  final String lessonTitle;
  final int score;
  final VoidCallback onNext;
  final VoidCallback onPracticeAgain;
  final VoidCallback onBack;

  @override
  ConsumerState<LessonCompletionOverlay> createState() =>
      _LessonCompletionOverlayState();
}

class _LessonCompletionOverlayState
    extends ConsumerState<LessonCompletionOverlay> {
  @override
  void initState() {
    super.initState();
    // Ask for a store review only on a genuine high-score delight moment.
    // The OS throttles how often the prompt is actually shown.
    if (widget.score >= 80) {
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) {
          ref.read(reviewServiceProvider).maybeRequestReview();
        }
      });
    }
  }

  bool get _hasNext {
    final int idx = _lessonOrder.indexOf(widget.lessonId);
    return idx >= 0 && idx < _lessonOrder.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool compact = MediaQuery.sizeOf(context).height < 520;
    return GestureDetector(
      // Block taps falling through to lesson body
      onTap: () {},
      child: Container(
        color: Colors.black.withAlpha(160),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 28,
                vertical: 20,
              ),
              child: _CompletionCard(
                cs: cs,
                lessonTitle: widget.lessonTitle,
                score: widget.score,
                hasNext: _hasNext,
                compact: compact,
                onNext: widget.onNext,
                onPracticeAgain: widget.onPracticeAgain,
                onBack: widget.onBack,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, curve: Curves.easeOut);
  }
}

// ─── Main Card ────────────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.cs,
    required this.lessonTitle,
    required this.score,
    required this.hasNext,
    required this.compact,
    required this.onNext,
    required this.onPracticeAgain,
    required this.onBack,
  });

  final ColorScheme cs;
  final String lessonTitle;
  final int score;
  final bool hasNext;
  final bool compact;
  final VoidCallback onNext;
  final VoidCallback onPracticeAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, compact ? 22 : 28, 24, 18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ScoreRing(score: score, cs: cs, compact: compact),
                SizedBox(height: compact ? 14 : 18),
                Text(
                      'Lesson Complete!',
                      style: TextStyle(
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: 0,
                      ),
                    )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  lessonTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurface.withAlpha(150),
                  ),
                ).animate(delay: 480.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 6),
                Text(
                  score >= 80
                      ? 'Magaling ka!'
                      : score >= 50
                      ? 'Sige, kaya mo!'
                      : 'Patuloy lang!',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(delay: 540.ms).fadeIn(duration: 300.ms),
                SizedBox(height: compact ? 18 : 24),
                if (hasNext) ...<Widget>[
                  _TappableButton(
                    label: 'Next Lesson',
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    cs: cs,
                    onTap: onNext,
                    delay: 600.ms,
                  ),
                  const SizedBox(height: 10),
                ],
                _TappableButton(
                  label: 'Practice Again',
                  icon: Icons.replay_rounded,
                  filled: false,
                  cs: cs,
                  onTap: onPracticeAgain,
                  delay: hasNext ? 680.ms : 600.ms,
                ),
                const SizedBox(height: 4),
                TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Back to Lessons',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                    )
                    .animate(delay: hasNext ? 740.ms : 660.ms)
                    .fadeIn(duration: 300.ms),
              ],
            ),
          ),
        )
        .animate()
        .slideY(
          begin: 0.18,
          end: 0,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(
          begin: 0.92,
          end: 1,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── Animated Score Ring (CustomPainter) ─────────────────────────────────────

class _ScoreRing extends StatefulWidget {
  const _ScoreRing({
    required this.score,
    required this.cs,
    required this.compact,
  });

  final int score;
  final ColorScheme cs;
  final bool compact;

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing> with TickerProviderStateMixin {
  late final AnimationController _arcCtrl;
  late final AnimationController _countCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _arcAnim;
  late final Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();

    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic);

    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnim = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Stagger: arc first, then count, then particles
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _arcCtrl.forward();
        _countCtrl.forward();
      }
    });
    if (widget.score >= 80) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _particleCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _countCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Color get _arcColor {
    if (widget.score >= 80) return const Color(0xFF46B986);
    if (widget.score >= 50) return const Color(0xFFF5A623);
    return widget.cs.onSurface.withAlpha(120);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _arcAnim,
            _countAnim,
            _particleCtrl,
          ]),
          builder: (BuildContext context, _) {
            final int displayScore = (_countAnim.value * widget.score).round();
            final double size = widget.compact ? 88 : 100;
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _RingPainter(
                  fraction: _arcAnim.value * widget.score / 100,
                  arcColor: _arcColor,
                  trackColor: widget.cs.surfaceContainerHighest,
                  particleProgress: _particleCtrl.value,
                  showParticles: widget.score >= 80,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$displayScore',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: widget.cs.onSurface,
                          height: 1,
                        ),
                      ),
                      Text(
                        'pts',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.cs.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        )
        .animate(delay: 150.ms)
        .scaleXY(
          begin: 0.7,
          end: 1,
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
    required this.particleProgress,
    required this.showParticles,
  });

  final double fraction;
  final Color arcColor;
  final Color trackColor;
  final double particleProgress;
  final bool showParticles;

  static const double _strokeWidth = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - _strokeWidth) / 2;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Score arc
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Confetti particles burst when score ≥ 80
    if (showParticles && particleProgress > 0) {
      _drawParticles(canvas, center, radius);
    }
  }

  void _drawParticles(Canvas canvas, Offset center, double radius) {
    final math.Random rng = math.Random(42);
    for (int i = 0; i < 16; i++) {
      final double angle = (i / 16) * 2 * math.pi;
      final double distance =
          (radius + 12 + rng.nextDouble() * 16) * particleProgress;
      final double opacity = (1 - particleProgress).clamp(0.0, 1.0) * 0.85;
      if (opacity <= 0) continue;

      final Offset pos =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);

      final Color particleColor = i % 3 == 0
          ? const Color(0xFF46B986)
          : i % 3 == 1
          ? const Color(0xFFF5A623)
          : const Color(0xFF6C8FEF);

      canvas.drawCircle(
        pos,
        2.5 * (1 - particleProgress * 0.4),
        Paint()..color = particleColor.withAlpha((opacity * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.particleProgress != particleProgress;
}

// ─── Tappable Button with Scale Feedback ─────────────────────────────────────

class _TappableButton extends StatefulWidget {
  const _TappableButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.cs,
    required this.onTap,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final ColorScheme cs;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_TappableButton> createState() => _TappableButtonState();
}

class _TappableButtonState extends State<_TappableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) {
            _pressCtrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _pressCtrl.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (BuildContext context, Widget? child) =>
                Transform.scale(scale: _scaleAnim.value, child: child),
            child: SizedBox(
              width: double.infinity,
              child: widget.filled
                  ? FilledButton.icon(
                      onPressed: null, // handled by GestureDetector
                      icon: Icon(widget.icon, size: 16),
                      label: Text(widget.label),
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: widget.cs.primary,
                        disabledForegroundColor: widget.cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(widget.icon, size: 16),
                      label: Text(widget.label),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: widget.cs.onSurface.withAlpha(
                          200,
                        ),
                        side: BorderSide(color: widget.cs.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          ),
        )
        .animate(delay: widget.delay)
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}
