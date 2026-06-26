import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/app/constants.dart';

import 'package:kudlit_ph/features/learning/domain/entities/lesson_mode.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_step.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_controller.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_state.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/butty_coach_panel.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/butty_help_sheet.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/learning_route_back.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/lesson_completion_overlay.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/lesson_progress_bar.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/lesson_top_bar.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/modes/draw_mode_body.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/modes/free_input_mode_body.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/modes/reference_mode_body.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';

class LessonStageScreen extends ConsumerStatefulWidget {
  const LessonStageScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonStageScreen> createState() => _LessonStageScreenState();
}

class _LessonStageScreenState extends ConsumerState<LessonStageScreen> {
  final GlobalKey<DrawModeBodyState> _drawKey = GlobalKey<DrawModeBodyState>();
  final GlobalKey<FreeInputModeBodyState> _freeKey =
      GlobalKey<FreeInputModeBodyState>();

  bool _showCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonControllerProvider.notifier).loadLesson(widget.lessonId);
    });
  }

  void _openHelp(LessonStep step) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ButtyHelpSheet(step: step),
    );
  }

  void _handleContinue(LessonState state) {
    final LessonController ctrl = ref.read(lessonControllerProvider.notifier);
    if (state.completed) {
      returnToLearn(context);
      return;
    }
    if (state.attemptStatus == AttemptStatus.correct) {
      ctrl.next();
      return;
    }
    switch (state.currentStep.mode) {
      case LessonMode.reference:
        ctrl.acknowledge();
      case LessonMode.draw:
        _drawKey.currentState?.submitToController();
      case LessonMode.freeInput:
        _freeKey.currentState?.submitToController();
    }
  }

  void _goToNextLesson(String currentLessonId) {
    const List<String> order = <String>[
      'vowels-01',
      'consonants-01',
      'consonants-02',
      'consonants-03',
      'consonants-04',
      'kudlit-01',
    ];
    final int idx = order.indexOf(currentLessonId);
    if (idx >= 0 && idx < order.length - 1) {
      context.pushReplacement('${AppConstants.routeLesson}/${order[idx + 1]}');
    } else {
      returnToLearn(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<LessonState?>>(lessonControllerProvider, (
      AsyncValue<LessonState?>? prev,
      AsyncValue<LessonState?> next,
    ) {
      final bool wasCompleted = prev?.value?.completed ?? false;
      final bool isCompleted = next.value?.completed ?? false;
      if (!wasCompleted && isCompleted) {
        setState(() => _showCompletion = true);
      }
    });

    final AsyncValue<LessonState?> async = ref.watch(lessonControllerProvider);
    if (!kIsWeb) ref.watch(yoloDrawingPadModelProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => _ErrorView(
            onRetry: () => ref
                .read(lessonControllerProvider.notifier)
                .loadLesson(widget.lessonId),
          ),
          data: (LessonState? data) {
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              children: <Widget>[
                _LessonScaffold(
                  state: data,
                  drawKey: _drawKey,
                  freeKey: _freeKey,
                  onOpenHelp: _openHelp,
                  onContinue: () => _handleContinue(data),
                  onRetry: () => ref
                      .read(lessonControllerProvider.notifier)
                      .resetAttempt(),
                ),
                if (_showCompletion)
                  LessonCompletionOverlay(
                    lessonId: widget.lessonId,
                    lessonTitle: data.lesson.title,
                    score: data.score,
                    onNext: () => _goToNextLesson(widget.lessonId),
                    onPracticeAgain: () {
                      setState(() => _showCompletion = false);
                      ref.read(lessonControllerProvider.notifier).restart();
                    },
                    onBack: () => returnToLearn(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LessonScaffold extends StatelessWidget {
  const _LessonScaffold({
    required this.state,
    required this.drawKey,
    required this.freeKey,
    required this.onOpenHelp,
    required this.onContinue,
    required this.onRetry,
  });

  final LessonState state;
  final GlobalKey<DrawModeBodyState> drawKey;
  final GlobalKey<FreeInputModeBodyState> freeKey;
  final void Function(LessonStep step) onOpenHelp;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final LessonStep step = state.currentStep;
    return Column(
      children: <Widget>[
        LessonTopBar(
          title: state.lesson.title,
          subtitle: state.lesson.subtitle,
          onClose: () => returnToLearn(context),
        ),
        LessonProgressBar(
          progress: state.progress,
          label:
              'Step ${state.currentStepIndex + 1} of '
              '${state.lesson.steps.length} — ${step.label}',
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (Widget child, Animation<double> anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: _ModeSwitcher(
              key: ValueKey<String>(step.id),
              step: step,
              status: state.attemptStatus,
              drawKey: drawKey,
              freeKey: freeKey,
            ),
          ),
        ),
        ButtyCoachPanel(
          message: state.buttyMessage,
          attemptStatus: state.attemptStatus,
          completed: state.completed,
          onContinue: onContinue,
          showPrimaryAction:
              state.completed ||
              state.attemptStatus == AttemptStatus.correct ||
              state.currentStep.mode == LessonMode.reference,
          actionLabel: _actionLabel(state),
          onRetry: onRetry,
          onAvatarTap: () => onOpenHelp(step),
          onAskHelp: () => onOpenHelp(step),
        ),
      ],
    );
  }

  String _actionLabel(LessonState state) {
    if (state.completed) return 'Finish';
    if (state.attemptStatus == AttemptStatus.correct) return 'Continue';
    switch (state.currentStep.mode) {
      case LessonMode.reference:
        return 'Got it';
      case LessonMode.draw:
        return 'Check drawing';
      case LessonMode.freeInput:
        return 'Check answer';
    }
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    super.key,
    required this.step,
    required this.status,
    required this.drawKey,
    required this.freeKey,
  });

  final LessonStep step;
  final AttemptStatus status;
  final GlobalKey<DrawModeBodyState> drawKey;
  final GlobalKey<FreeInputModeBodyState> freeKey;

  @override
  Widget build(BuildContext context) {
    switch (step.mode) {
      case LessonMode.reference:
        return ReferenceModeBody(step: step, attemptStatus: status);
      case LessonMode.draw:
        return DrawModeBody(key: drawKey, step: step, attemptStatus: status);
      case LessonMode.freeInput:
        return FreeInputModeBody(
          key: freeKey,
          step: step,
          attemptStatus: status,
        );
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            const Text(
              'We couldn\'t load this lesson.\nPlease try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => returnToLearn(context),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
