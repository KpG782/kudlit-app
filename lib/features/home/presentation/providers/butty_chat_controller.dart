import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/features/home/domain/entities/profile_summary.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/home/presentation/utils/safe_ai_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/chat_msg.dart';
import 'package:kudlit_ph/features/learning/domain/entities/gemma_prompts.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_history_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_memory_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/memory_extraction_service.dart';

@immutable
class ButtyChatState {
  const ButtyChatState({required this.messages, required this.responding});

  factory ButtyChatState.initial() {
    return const ButtyChatState(
      messages: <ChatMsg>[
        (
          isButty: true,
          text:
              'Hoy, kumusta! I\'m Butty — I eat Baybayin for breakfast. '
              'Ask me about the ancient script, why it almost disappeared, '
              'how to write your name, or literally anything about Philippine '
              'writing. I\'m hyped. Go.',
        ),
      ],
      responding: false,
    );
  }

  final List<ChatMsg> messages;
  final bool responding;

  ButtyChatState copyWith({List<ChatMsg>? messages, bool? responding}) {
    return ButtyChatState(
      messages: messages ?? this.messages,
      responding: responding ?? this.responding,
    );
  }
}

final NotifierProvider<ButtyChatController, ButtyChatState>
buttyChatControllerProvider =
    NotifierProvider<ButtyChatController, ButtyChatState>(
      ButtyChatController.new,
    );

class ButtyChatController extends Notifier<ButtyChatState> {
  /// Last K turns sent to Gemma per inference. Larger windows = better local
  /// recall but quickly inflate token cost; the memory layer covers anything
  /// older than this window.
  static const int _historyWindow = 20;

  int _userMessageCount = 0;

  @override
  ButtyChatState build() {
    Future.microtask(_loadHistory);
    return ButtyChatState.initial();
  }

  Future<void> _loadHistory() async {
    try {
      final List<ChatMessage> history = await ref.read(
        chatHistoryNotifierProvider.future,
      );
      _userMessageCount = history.where((ChatMessage m) => m.isUser).length;
      if (history.isEmpty) return;
      final List<ChatMsg> loaded = history
          .map((ChatMessage m) => (isButty: !m.isUser, text: m.text))
          .toList();
      state = ButtyChatState(
        messages: <ChatMsg>[state.messages.first, ...loaded],
        responding: false,
      );
    } catch (_) {
      // History load failure is non-fatal
    }
  }

  Future<void> send(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || state.responding) {
      return;
    }

    final AiPreference mode =
        ref.read(appPreferencesNotifierProvider).value?.aiPreference ??
        AiPreference.cloud;
    debugPrint(
      '[Butty] send requested | mode=${mode.name} | chars=${trimmed.length}',
    );

    final List<ChatMsg> nextMessages = <ChatMsg>[
      ...state.messages,
      (isButty: false, text: trimmed),
    ];
    state = state.copyWith(messages: nextMessages, responding: true);

    unawaited(
      ref
          .read(chatHistoryNotifierProvider.notifier)
          .addMessage(
            ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
          ),
    );

    _userMessageCount += 1;

    final List<ChatMsg> windowed = nextMessages.length <= _historyWindow
        ? nextMessages
        : nextMessages.sublist(nextMessages.length - _historyWindow);

    final List<ChatMessage> history = windowed
        .map((ChatMsg msg) {
          return ChatMessage(
            text: msg.text,
            isUser: !msg.isButty,
            timestamp: DateTime.now(),
          );
        })
        .toList(growable: false);

    final String systemInstruction = await _buildSystemInstruction();

    try {
      final Stream<String> responseStream = ref
          .read(aiInferenceNotifierProvider.notifier)
          .generateResponse(history, systemInstruction: systemInstruction);
      debugPrint('[Butty] response stream opened');

      state = state.copyWith(
        messages: <ChatMsg>[...state.messages, (isButty: true, text: '')],
      );

      final StringBuffer buffer = StringBuffer();
      await for (final String chunk in responseStream) {
        buffer.write(chunk);
        final String displayText = cleanAssistantOutput(buffer.toString());
        state = state.copyWith(
          messages: <ChatMsg>[
            ...state.messages.take(state.messages.length - 1),
            (isButty: true, text: displayText),
          ],
        );
      }
      final String full = buffer.toString();
      debugPrint('[Butty] response completed | chars=${full.length}');
      if (full.trim().isEmpty) {
        // Zero-token / blocked response — show a fallback instead of a silent
        // blank bubble (the message list filters out empty Butty bubbles).
        state = state.copyWith(
          messages: <ChatMsg>[
            ...state.messages.take(state.messages.length - 1),
            (
              isButty: true,
              text: 'Hmm, I blanked on that one — try rephrasing?',
            ),
          ],
        );
      } else {
        unawaited(
          ref
              .read(chatHistoryNotifierProvider.notifier)
              .addMessage(
                ChatMessage(
                  text: full,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              ),
        );

        // Memory extraction runs in the background — never blocks the user.
        unawaited(
          ref
              .read(memoryExtractionServiceProvider)
              .extractIfDue(_userMessageCount),
        );
      }
    } catch (_) {
      debugPrint('[Butty] response failed');
      state = state.copyWith(
        messages: <ChatMsg>[
          ...state.messages,
          (
            isButty: true,
            text: 'Oops, I had trouble thinking about that. Try again?',
          ),
        ],
      );
    } finally {
      debugPrint('[Butty] responding=false');
      state = state.copyWith(responding: false);
    }
  }

  /// Triggered from the chat screen's lifecycle observer when the app pauses.
  /// Distills any unflushed turns into memory facts so nothing is lost when
  /// the user backgrounds the app.
  Future<void> flushMemoryNow() async {
    await ref.read(memoryExtractionServiceProvider).extractNow();
  }

  /// "Start fresh" — clears the visible conversation and the chat_messages
  /// store (local + remote) but preserves chat_memory_facts so Butty still
  /// remembers what the user has shared in past sessions.
  Future<void> startFresh() async {
    await ref.read(chatHistoryNotifierProvider.notifier).clearHistory();
    _userMessageCount = 0;
    state = ButtyChatState.initial();
  }

  // ─── Prompt assembly ──────────────────────────────────────────────────────

  Future<String> _buildSystemInstruction() async {
    final String profileBlock = _buildProfileBlock();
    final String memoryBlock = await _buildMemoryBlock();
    return GemmaPrompts.assistantModeWithContext(
      profileBlock: profileBlock,
      memoryBlock: memoryBlock,
    );
  }

  String _buildProfileBlock() {
    final Option<ProfileSummary> opt =
        ref.read(profileSummaryNotifierProvider).value ?? const None();
    return opt.fold(() => '', (ProfileSummary s) {
      final List<String> lines = <String>[];
      if ((s.displayName ?? '').trim().isNotEmpty) {
        lines.add('Name: ${s.displayName!.trim()}');
      }
      if (s.completedLessons > 0) {
        lines.add('Lessons completed: ${s.completedLessons}');
      }
      final AiPreference mode =
          ref.read(appPreferencesNotifierProvider).value?.aiPreference ??
          AiPreference.cloud;
      lines.add('AI mode: ${mode.name}');
      return lines.join('\n');
    });
  }

  Future<String> _buildMemoryBlock() async {
    try {
      final List<ChatMemoryFact> facts = await ref.read(
        chatMemoryNotifierProvider.future,
      );
      if (facts.isEmpty) return '';
      // Take the 12 most-recent facts. The list is already sorted DESC by
      // created_at in the local datasource.
      final List<ChatMemoryFact> top = facts.take(12).toList(growable: false);
      return top.map((ChatMemoryFact f) => '- ${f.content}').join('\n');
    } catch (e) {
      debugPrint('[Butty] memory block build failed (non-fatal): $e');
      return '';
    }
  }
}
