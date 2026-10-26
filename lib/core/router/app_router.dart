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
import '../../features/notes/ui/widgets/note_card.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/topics/ui/topics_screen.dart';
import '../../shared/extensions/datetime_ext.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();

  ref.listen<AuthStatus>(authStatusProvider, (_, __) => notifier.refresh());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: _buildRedirect(ref),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(successBanner: state.extra as String?),
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
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
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
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1 — Categories (AI-organised).
          StatefulShellBranch(
            routes: [
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
                        intentType: intentType,
                        label: label,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      final name = state.extra as String?;
                      return _CategoryNotesScreen(
                        categoryId: id,
                        categoryName: name,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 2 — Ask AI
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ask',
                builder: (context, state) => const AskScreen(),
              ),
            ],
          ),
          // Tab 3 — Conversations
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conversations',
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),
          // Tab 4 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
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
    final isPublic =
        isSplash ||
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

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.folder_outlined,
      selected: Icons.folder_rounded,
      label: 'Categories',
    ),
    (
      icon: Icons.auto_awesome_outlined,
      selected: Icons.auto_awesome,
      label: 'Ask AI',
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      selected: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings_rounded,
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
          final extended = constraints.maxWidth >= 840;
          return Scaffold(
            body: Row(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(Theme.of(context).colorScheme),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: NavigationRail(
                    extended: extended,
                    minExtendedWidth: 220,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onTap,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: SparkleOrb(size: 40),
                    ),
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: _FloatingNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
          ),
        );
      },
    );
  }
}

/// Dark floating pill with icon-only tabs and a raised "Ask AI" orb in the
/// middle. The selected tab sits in a light circle.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF2A2136) : AppColors.ink;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(34),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _NavigationShell._destinations.length; i++)
                i == 2
                    ? _AskOrbButton(
                        selected: currentIndex == 2,
                        onTap: () => onTap(2),
                      )
                    : _NavIcon(
                        destination: _NavigationShell._destinations[i],
                        selected: currentIndex == i,
                        onTap: () => onTap(i),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData selected, String label}) destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppColors.mist : Colors.white;
    final activeFg = isDark ? const Color(0xFF1A1222) : AppColors.ink;

    return Semantics(
      label: destination.label,
      button: true,
      selected: selected,
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: destination.label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? activeBg : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              selected ? destination.selected : destination.icon,
              size: 22,
              color: selected ? activeFg : Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ),
      ),
    );
  }
}

class _AskOrbButton extends StatelessWidget {
  const _AskOrbButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.aiGradient(Theme.of(context).brightness);
    return Semantics(
      label: 'Ask AI',
      button: true,
      selected: selected,
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: 'Ask AI',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withValues(alpha: 0.5),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category notes screen ────────────────────────────────────────────────────

class _CategoryNotesScreen extends ConsumerStatefulWidget {
  const _CategoryNotesScreen({required this.categoryId, this.categoryName});

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
    return _IntentNotesScaffold(
      title: widget.categoryName ?? 'Notes',
      notesFuture: _notesFuture,
      emptyMessage: 'No notes in this category yet.',
      onReload: () => setState(_load),
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
    final matching = all
        .where((c) => c.intentType == widget.intentType)
        .toList();

    if (matching.isEmpty) return [];

    final repo = ref.read(intentsRepositoryProvider);
    final results = await Future.wait(
      matching.map((c) => repo.listNotesForCategory(c.id)),
    );

    final merged = results.expand((list) => list).toList();
    // Deduplicate by note id (same note can appear in multiple categories).
    final seen = <int>{};
    final deduped = merged.where((n) => seen.add(n.id)).toList();
    deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deduped;
  }

  @override
  Widget build(BuildContext context) {
    return _IntentNotesScaffold(
      title: widget.label ?? widget.intentType,
      notesFuture: _notesFuture,
      emptyMessage: 'No notes here yet.',
      onReload: () => setState(_load),
    );
  }
}

/// Shared body for the two category note lists above.
class _IntentNotesScaffold extends StatelessWidget {
  const _IntentNotesScaffold({
    required this.title,
    required this.notesFuture,
    required this.emptyMessage,
    required this.onReload,
  });

  final String title;
  final Future<List<IntentNoteResponse>> notesFuture;
  final String emptyMessage;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<IntentNoteResponse>>(
        future: notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const NoteCardSkeleton(),
            );
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: onReload,
            );
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return EmptyState(message: emptyMessage);
          }
          return RefreshIndicator(
            onRefresh: () async => onReload(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 96),
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final note = notes[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: NoteTile(
                    title: note.title,
                    content: note.content,
                    onTap: () => context.push('/notes/${note.id}'),
                    footer: [
                      Text(
                        note.createdAt.relative,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
