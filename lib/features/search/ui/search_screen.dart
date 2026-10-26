import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/search_provider.dart';
import 'widgets/search_result_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _debouncedQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _queryCtrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search notes…',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: cs.secondary, width: 1.6),
              ),
              suffixIcon: _queryCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear',
                      onPressed: () {
                        _queryCtrl.clear();
                        setState(() => _debouncedQuery = '');
                        _debounce?.cancel();
                      },
                    )
                  : null,
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 46,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Smart'),
                Tab(text: 'Semantic'),
                Tab(text: 'Chunks'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SmartTab(query: _debouncedQuery),
          _SemanticTab(query: _debouncedQuery),
          _HybridTab(query: _debouncedQuery),
        ],
      ),
    );
  }
}

// ── Smart tab ─────────────────────────────────────────────────────────────────

class _SmartTab extends ConsumerWidget {
  const _SmartTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        message: 'Start typing to search your notes.',
      );
    }

    final async = ref.watch(smartSearchProvider(query));
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(smartSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No notes found for this query.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: results.length,
              itemBuilder: (_, i) => NoteSearchResultTile(result: results[i]),
            ),
    );
  }
}

// ── Semantic tab ──────────────────────────────────────────────────────────────

class _SemanticTab extends ConsumerWidget {
  const _SemanticTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const EmptyState(
        message: 'Chunk-level semantic search.\nStart typing to retrieve.',
      );
    }

    final async = ref.watch(semanticSearchProvider(query));
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(semanticSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No results found.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: results.length,
              itemBuilder: (_, i) => ChunkResultTile(result: results[i]),
            ),
    );
  }
}

// ── Hybrid tab ────────────────────────────────────────────────────────────────

class _HybridTab extends ConsumerWidget {
  const _HybridTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const EmptyState(
        message: 'Intent-aware hybrid search.\nStart typing to retrieve.',
      );
    }

    final async = ref.watch(hybridSearchProvider(query));
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(hybridSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No results found.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: results.length,
              itemBuilder: (_, i) => ChunkResultTile(result: results[i]),
            ),
    );
  }
}
