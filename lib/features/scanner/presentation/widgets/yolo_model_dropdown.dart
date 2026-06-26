import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';

/// Compact dropdown that lets the user pick which Baybayin YOLO model is
/// active for the given [scope].
///
/// Usage:
/// ```dart
/// YoloModelDropdown(scope: YoloModelScope.camera)
/// ```
///
/// Selecting a model writes the choice via [yoloModelSelectionProvider]
/// (per-scope override). The path resolver then re-downloads the model if the
/// catalog version is newer than the locally cached one.
///
/// Disabled models (`enabled = false` in Supabase) are filtered server-side
/// and never appear here.
class YoloModelDropdown extends ConsumerWidget {
  const YoloModelDropdown({required this.scope, super.key});

  /// The scope this dropdown writes to. Use a [YoloModelScope] constant
  /// (e.g. `YoloModelScope.camera`) so multiple widgets in the same screen
  /// stay in sync.
  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AiModelInfo>> modelsAsync = ref.watch(
      availableYoloModelsProvider,
    );
    final AsyncValue<AiModelInfo?> activeAsync = ref.watch(
      activeYoloModelProvider(scope),
    );

    return modelsAsync.when(
      loading: () => const _DropdownShell(child: _DropdownSpinner()),
      error: (Object e, _) => GestureDetector(
        onTap: () => ref.invalidate(availableYoloModelsProvider),
        child: _DropdownShell(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Retry models',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withAlpha(220)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (List<AiModelInfo> models) {
        if (models.length == 1) {
          return const SizedBox.shrink();
        }
        if (models.isEmpty) {
          return const _DropdownShell(
            child: Text('No models', style: TextStyle(color: Colors.white70)),
          );
        }
        final AiModelInfo? active = activeAsync.value;
        return _DropdownShell(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: active?.id,
              isDense: true,
              dropdownColor: const Color(0xFF0E1425),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: models
                  .map(
                    (AiModelInfo m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (String? id) {
                if (id == null) return;
                ref
                    .read(yoloModelSelectionProvider.notifier)
                    .setForScope(scope, id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Scanner model',
      child: Semantics(
        label: 'Scanner model picker',
        button: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1425).withAlpha(160),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DropdownSpinner extends StatelessWidget {
  const _DropdownSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
