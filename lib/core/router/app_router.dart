import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ask/ui/ask_screen.dart';
import '../../features/auth/ui/forgot_password_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/conversations/ui/conversation_screen.dart';
import '../../features/conversations/ui/conversations_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/categories/ui/categories_screen.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/intents/data/intents_repository.dart';
import '../../features/intents/data/models/intent_note_response.dart';
import '../../features/intents/providers/intents_provider.dart';
import '../../features/intents/ui/intents_screen.dart';
import '../../features/notes/ui/create_note_screen.dart';
import '../../features/notes/ui/note_detail_screen.dart';
import '../../features/notes/ui/notes_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/topics/ui/topics_screen.dart';
import '../auth/auth_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();

  ref.listen<AuthStatus>(authStatusProvider, (_, __) => notifier.refresh());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: _buildRedirect(ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          successBanner: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Notes — push destination (all notes, create, detail).
      // Accessed from dashboard, search results, and category note lists.
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateNoteScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoteDetailScreen(noteId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/topics',
        builder: (context, state) => const TopicsScreen(),
      ),
      GoRoute(
        path: '/conversations/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ConversationScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/intents',
        builder: (context, state) => const IntentsScreen(),
        routes: [
          GoRoute(
            path: ':id/notes',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _IntentCategoryNotesScreen(categoryId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Shell: bottom nav with 5 tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _NavigationShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          // Tab 1 — Categories (AI-organised).
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
              routes: [
                GoRoute(
                  path: 't/:intentType',
                  builder: (context, state) {
                    final intentType =
                        state.pathParameters['intentType'] ?? '';
                    final label = state.extra as String?;
                    return _GroupedNotesScreen(
                        intentType: intentType, label: label);
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id =
                        int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    final name = state.extra as String?;
                    return _CategoryNotesScreen(
                        categoryId: id, categoryName: name);
                  },
                ),
              ],
            ),
          ]),
          // Tab 2 — Ask AI
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ask',
              builder: (context, state) => const AskScreen(),
            ),
          ]),
          // Tab 3 — Conversations
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/conversations',
              builder: (context, state) => const ConversationsScreen(),
            ),
          ]),
          // Tab 4 — Settings
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

GoRouterRedirect _buildRedirect(Ref ref) {
  return (BuildContext context, GoRouterState state) {

    final status = ref.read(authStatusProvider);
    final location = state.matchedLocation;
    final isSplash = location == '/';
    final isPublic = isSplash ||
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password';

    if (status == AuthStatus.unknown) {
      return isSplash ? null : '/';
    }

    if (isSplash) {
      return status == AuthStatus.authenticated ? '/dashboard' : '/login';
    }

    if (status == AuthStatus.unauthenticated && !isPublic) {
      return '/login';
    }

    if (status == AuthStatus.authenticated && isPublic) {
      return '/dashboard';
    }

    return null;
  };
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class _NavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _NavigationShell({required this.navigationShell});

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: Text('Categories'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome),
      label: Text('Ask AI'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: Text('Chats'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  static const _barDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Categories',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome),
      label: 'Ask AI',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chats',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 840,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onTap,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: _barDestinations,
          ),
        );
      },
    );
  }
}

// ── Category notes screen ────────────────────────────────────────────────────

class _CategoryNotesScreen extends ConsumerStatefulWidget {
  const _CategoryNotesScreen({
    required this.categoryId,
    this.categoryName,
  });

  final int categoryId;
  final String? categoryName;

  @override
  ConsumerState<_CategoryNotesScreen> createState() =>
      _CategoryNotesScreenState();
}

class _CategoryNotesScreenState extends ConsumerState<_CategoryNotesScreen> {
  late Future<List<IntentNoteResponse>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _notesFuture = ref
        .read(intentsRepositoryProvider)
        .listNotesForCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<IntentNoteResponse>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notes in this category yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final note = notes[i];
                return ListTile(
                  title: Text(note.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: note.content != null
                      ? Text(note.content!,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                      : null,
                  onTap: () => context.push('/notes/${note.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Grouped notes screen — all notes for an intent type ─────────────────────

class _GroupedNotesScreen extends ConsumerStatefulWidget {
  const _GroupedNotesScreen({required this.intentType, this.label});

  final String intentType;
  final String? label;

  @override
  ConsumerState<_GroupedNotesScreen> createState() =>
      _GroupedNotesScreenState();
}

class _GroupedNotesScreenState extends ConsumerState<_GroupedNotesScreen> {
  late Future<List<IntentNoteResponse>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _notesFuture = _fetchAll();
  }

  Future<List<IntentNoteResponse>> _fetchAll() async {
    final all = ref.read(intentsProvider).valueOrNull ?? [];
    final matching =
        all.where((c) => c.intentType == widget.intentType).toList();

    if (matching.isEmpty) return [];

    final repo = ref.read(intentsRepositoryProvider);
    final results = await Future.wait(
      matching.map((c) => repo.listNotesForCategory(c.id)),
    );

    final merged = results.expand((list) => list).toList();
    // Deduplicate by note id (same note can appear in multiple categories).
    final seen = <int>{};
    final deduped =
        merged.where((n) => seen.add(n.id)).toList();
    deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deduped;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.label ?? widget.intentType;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<IntentNoteResponse>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notes here yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final note = notes[i];
                return ListTile(
                  title: Text(note.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: note.content != null
                      ? Text(note.content!,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                      : null,
                  onTap: () => context.push('/notes/${note.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Intent category notes screen (from /intents tab) ────────────────────────

class _IntentCategoryNotesScreen extends StatelessWidget {
  const _IntentCategoryNotesScreen({required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organised Notes')),
      body: Center(child: Text('Intent category $categoryId — Phase 5')),
    );
  }
}
