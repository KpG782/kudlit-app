import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/streak_provider.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/learn_home/butty_talk_card.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/learn_home/learn_section_label.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/learn_home/lesson_card.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_progress_provider.dart';

const List<String> _lessonOrder = <String>[
  'vowels-01',
  'consonants-01',
  'consonants-02',
  'consonants-03',
  'consonants-04',
  'kudlit-01',
];

const List<_LessonMeta> _lessons = <_LessonMeta>[
  _LessonMeta(
    id: 'vowels-01',
    title: 'Baybayin Basics',
    subtitle: 'A, E/I, O/U',
    glyphCount: 3,
    estimatedLength: '4 min',
    items: <(String, String)>[('a', 'A'), ('e', 'E / I'), ('o', 'O / U')],
  ),
  _LessonMeta(
    id: 'consonants-01',
    title: 'Core Consonants',
    subtitle: 'Ba, Ka, Da/Ra, Ga',
    glyphCount: 4,
    estimatedLength: '6 min',
    items: <(String, String)>[
      ('b+', 'BA'),
      ('k+', 'KA'),
      ('d+', 'DA/RA'),
      ('g+', 'GA'),
    ],
  ),
  _LessonMeta(
    id: 'consonants-02',
    title: 'The Waves',
    subtitle: 'Ha, La, Ma, Na',
    glyphCount: 4,
    estimatedLength: '6 min',
    items: <(String, String)>[
      ('h+', 'HA'),
      ('l+', 'LA'),
      ('m+', 'MA'),
      ('n+', 'NA'),
    ],
  ),
  _LessonMeta(
    id: 'consonants-03',
    title: 'The Loops',
    subtitle: 'Nga, Pa, Sa, Ta',
    glyphCount: 4,
    estimatedLength: '6 min',
    items: <(String, String)>[
      ('ng', 'NGA'),
      ('p+', 'PA'),
      ('s+', 'SA'),
      ('t+', 'TA'),
    ],
  ),
  _LessonMeta(
    id: 'consonants-04',
    title: 'The Tails',
    subtitle: 'Wa, Ya',
    glyphCount: 2,
    estimatedLength: '3 min',
    items: <(String, String)>[('w+', 'WA'), ('y+', 'YA')],
  ),
  _LessonMeta(
    id: 'kudlit-01',
    title: 'The Kudlit',
    subtitle: 'Changing vowel sounds',
    glyphCount: 3,
    estimatedLength: '5 min',
    items: <(String, String)>[('b', 'BA'), ('be', 'BE/BI'), ('bo', 'BO/BU')],
  ),
];

class _LessonMeta {
  const _LessonMeta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.glyphCount,
    required this.estimatedLength,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final int glyphCount;
  final String estimatedLength;
  final List<(String, String)> items;
}

class LearnHomeBody extends ConsumerWidget {
  const LearnHomeBody({
    super.key,
    required this.onStartLesson,
    required this.onChatWithButty,
    required this.onOpenGallery,
    required this.onStartQuiz,
    required this.bottomPad,
  });

  final void Function(String) onStartLesson;
  final VoidCallback onChatWithButty;
  final VoidCallback onOpenGallery;
  final VoidCallback onStartQuiz;
  final double bottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, LessonProgress>> progressAsync = ref.watch(
      lessonProgressNotifierProvider,
    );
    final Map<String, LessonProgress> progressMap =
        progressAsync.value ?? <String, LessonProgress>{};
    // The lesson list is static, so we keep showing it; but if progress failed
    // to load we surface a non-blocking retry banner so a sync error doesn't
    // silently read as "nothing completed / everything locked".
    final bool progressFailed = progressAsync.hasError && !progressAsync.hasValue;

    final int streakCount = ref.watch(streakProvider).value ?? 0;

    bool locked(int lessonIndex) {
      if (lessonIndex == 0) return false;
      return progressMap[_lessonOrder[lessonIndex - 1]]?.status !=
          LessonStatus.completed;
    }

    final bool hasCompletedAny = progressMap.values.any(
      (LessonProgress p) => p.status == LessonStatus.completed,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ButtyTalkCard(onTap: onChatWithButty),
              const SizedBox(height: 14),
              if (progressFailed) ...<Widget>[
                _ProgressSyncErrorBanner(
                  onRetry: () =>
                      ref.invalidate(lessonProgressNotifierProvider),
                ),
                const SizedBox(height: 14),
              ],
              _QuickActionsRow(
                streakCount: streakCount,
                hasCompletedAny: hasCompletedAny,
                onOpenGallery: onOpenGallery,
                onStartQuiz: onStartQuiz,
              ),
              const SizedBox(height: 18),
              const LearnSectionLabel(text: 'Lessons'),
              const SizedBox(height: 10),
              for (int i = 0; i < _lessons.length; i++) ...<Widget>[
                LessonCard(
                  index: i + 1,
                  title: _lessons[i].title,
                  subtitle: _lessons[i].subtitle,
                  glyphCount: _lessons[i].glyphCount,
                  estimatedLength: _lessons[i].estimatedLength,
                  items: _lessons[i].items,
                  isLocked: locked(i),
                  lockedReason: i == 0
                      ? null
                      : 'Complete ${_lessons[i - 1].title} first',
                  progress: progressMap[_lessons[i].id],
                  onStart: () => onStartLesson(_lessons[i].id),
                ),
                if (i != _lessons.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSyncErrorBanner extends StatelessWidget {
  const _ProgressSyncErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: cs.errorContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withAlpha(70)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Couldn\'t sync your progress.',
              style: TextStyle(fontSize: 12.5, color: cs.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.streakCount,
    required this.hasCompletedAny,
    required this.onOpenGallery,
    required this.onStartQuiz,
  });

  final int streakCount;
  final bool hasCompletedAny;
  final VoidCallback onOpenGallery;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (streakCount > 0) ...<Widget>[
              _StreakChip(count: streakCount, cs: cs),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _QuickActionButton(
                onPressed: onOpenGallery,
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: 'Glyphs',
                cs: cs,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                onPressed: hasCompletedAny ? onStartQuiz : null,
                icon: const Icon(Icons.quiz_rounded, size: 16),
                label: 'Quiz',
                cs: cs,
                isFilled: true,
              ),
            ),
          ],
        ),
        if (!hasCompletedAny) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'Quick Quiz unlocks after one completed lesson.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.cs,
    this.isFilled = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final ColorScheme cs;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color foreground = enabled
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.38);
    final Color background = isFilled
        ? (enabled ? cs.primaryContainer : cs.surfaceContainerHighest)
        : Colors.transparent;
    final BorderSide border = BorderSide(
      color: enabled ? cs.outline : cs.outline.withValues(alpha: 0.46),
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: border,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 16),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    icon,
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.count, required this.cs});

  final int count;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('\u{1F525}', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cs.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
