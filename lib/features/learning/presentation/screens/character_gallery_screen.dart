import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/learning/domain/entities/glyph_entry.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/character_gallery_provider.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/baybayin_glyph_mark.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/glyph_detail_sheet.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/learning_route_back.dart';

const List<_GalleryFilter> _kFilters = <_GalleryFilter>[
  _GalleryFilter('All', null),
  _GalleryFilter('Vowels', 'Vowels'),
  _GalleryFilter('Consonants', 'Consonants'),
  _GalleryFilter('Kudlit marks', 'Kudlit'),
];

const List<String> _kGroupOrder = <String>['Vowels', 'Consonants', 'Kudlit'];

class CharacterGalleryScreen extends ConsumerStatefulWidget {
  const CharacterGalleryScreen({super.key});

  @override
  ConsumerState<CharacterGalleryScreen> createState() =>
      _CharacterGalleryScreenState();
}

class _CharacterGalleryScreenState
    extends ConsumerState<CharacterGalleryScreen> {
  final TextEditingController _search = TextEditingController();
  String? _groupFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<GlyphEntry>> state = ref.watch(
      characterGalleryProvider,
    );
    return Scaffold(
      appBar: AppBar(
        leading: const LearnRouteBackButton(),
        title: const Text('All Glyphs'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => _GalleryErrorBody(
          onRetry: () => ref.invalidate(characterGalleryProvider),
        ),
        data: (List<GlyphEntry> entries) => _GalleryBody(
          entries: entries,
          query: _search.text,
          groupFilter: _groupFilter,
          search: _search,
          onSearchChanged: (_) => setState(() {}),
          onFilterChanged: (String? group) {
            setState(() => _groupFilter = group);
          },
        ),
      ),
    );
  }
}

class _GalleryFilter {
  const _GalleryFilter(this.label, this.group);

  final String label;
  final String? group;
}

class _GalleryErrorBody extends StatelessWidget {
  const _GalleryErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Could not load glyphs.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({
    required this.entries,
    required this.query,
    required this.groupFilter,
    required this.search,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final List<GlyphEntry> entries;
  final String query;
  final String? groupFilter;
  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final List<GlyphEntry> filtered = _filteredEntries();
    final Map<String, List<GlyphEntry>> grouped = _grouped(filtered);
    final List<String> orderedGroups = _kGroupOrder
        .where(grouped.containsKey)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GalleryControls(
                  search: search,
                  groupFilter: groupFilter,
                  onSearchChanged: onSearchChanged,
                  onFilterChanged: onFilterChanged,
                ),
                const SizedBox(height: 14),
                if (orderedGroups.isEmpty)
                  _EmptyGalleryMessage(
                    query: query,
                    groupLabel: _labelForGroup(groupFilter),
                  )
                else
                  for (final String group in orderedGroups)
                    _GallerySection(
                      title: group == 'Kudlit' ? 'Kudlit marks' : group,
                      entries: grouped[group]!,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<GlyphEntry> _filteredEntries() {
    final String needle = query.trim().toLowerCase();
    return entries
        .where((GlyphEntry entry) {
          final bool matchesGroup =
              groupFilter == null || entry.group == groupFilter;
          final bool matchesSearch =
              needle.isEmpty ||
              entry.label.toLowerCase().contains(needle) ||
              entry.glyph.toLowerCase().contains(needle) ||
              entry.group.toLowerCase().contains(needle);
          return matchesGroup && matchesSearch;
        })
        .toList(growable: false);
  }

  Map<String, List<GlyphEntry>> _grouped(List<GlyphEntry> filtered) {
    final Map<String, List<GlyphEntry>> grouped = <String, List<GlyphEntry>>{};
    for (final GlyphEntry entry in filtered) {
      grouped.putIfAbsent(entry.group, () => <GlyphEntry>[]).add(entry);
    }
    return grouped;
  }

  String? _labelForGroup(String? group) {
    if (group == null) return null;
    for (final _GalleryFilter filter in _kFilters) {
      if (filter.group == group) return filter.label;
    }
    return group;
  }
}

class _GalleryControls extends StatelessWidget {
  const _GalleryControls({
    required this.search,
    required this.groupFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final TextEditingController search;
  final String? groupFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: search,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search label or glyph',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final _GalleryFilter filter in _kFilters)
              ChoiceChip(
                label: Text(filter.label),
                selected: groupFilter == filter.group,
                onSelected: (_) => onFilterChanged(filter.group),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyGalleryMessage extends StatelessWidget {
  const _EmptyGalleryMessage({required this.query, required this.groupLabel});

  final String query;
  final String? groupLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String message = query.trim().isNotEmpty
        ? 'No glyphs match that search.'
        : groupLabel == null
        ? 'No glyphs are loaded yet.'
        : '$groupLabel are not loaded yet.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.title, required this.entries});

  final String title;
  final List<GlyphEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 560 ? 2 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 10),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 3.8 : 3.15,
              ),
              itemCount: entries.length,
              itemBuilder: (BuildContext context, int i) =>
                  _GlyphCell(entry: entries[i]),
            ),
          ],
        );
      },
    );
  }
}

class _GlyphCell extends StatelessWidget {
  const _GlyphCell({required this.entry});

  final GlyphEntry entry;

  void _onTap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlyphDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasStroke =
        entry.strokeOrder != null && !entry.strokeOrder!.isEmpty;
    return Card(
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.hardEdge,
      child: Semantics(
        button: true,
        label:
            '${entry.label} glyph. '
            '${entry.group == 'Kudlit' ? 'Kudlit marks' : entry.group}. '
            '${hasStroke ? 'Stroke order available.' : 'Stroke order not recorded.'}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _onTap(context),
          child: _GlyphCellContent(entry: entry, hasStroke: hasStroke, cs: cs),
        ),
      ),
    );
  }
}

class _GlyphCellContent extends StatelessWidget {
  const _GlyphCellContent({
    required this.entry,
    required this.hasStroke,
    required this.cs,
  });

  final GlyphEntry entry;
  final bool hasStroke;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Semantics(
            label: '${entry.label} glyph',
            child: BaybayinGlyphMark(
              glyph: entry.glyph,
              size: 44,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.group == 'Kudlit' ? 'Kudlit marks' : entry.group,
                  style: text.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (hasStroke)
            Icon(
              Icons.play_circle_outline_rounded,
              size: 20,
              color: cs.onPrimaryContainer.withValues(alpha: 0.65),
            ),
        ],
      ),
    );
  }
}
