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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _queryCtrl,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Search notes…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _queryCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _queryCtrl.clear();
                      setState(() => _debouncedQuery = '');
                      _debounce?.cancel();
                    },
                  )
                : null,
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Smart'),
            Tab(text: 'Semantic'),
            Tab(text: 'Chunks'),
          ],
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
      return const EmptyState(message: 'Start typing to search your notes.');
    }

    final async = ref.watch(smartSearchProvider(query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(smartSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No notes found for this query.')
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) =>
                  NoteSearchResultTile(result: results[i]),
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
          message: 'Chunk-level semantic search.\nStart typing to retrieve.');
    }

    final async = ref.watch(semanticSearchProvider(query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(semanticSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No results found.')
          : ListView.builder(
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
          message:
              'Intent-aware hybrid search.\nStart typing to retrieve.');
    }

    final async = ref.watch(hybridSearchProvider(query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(hybridSearchProvider(query)),
      ),
      data: (results) => results.isEmpty
          ? const EmptyState(message: 'No results found.')
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) => ChunkResultTile(result: results[i]),
            ),
    );
  }
}
