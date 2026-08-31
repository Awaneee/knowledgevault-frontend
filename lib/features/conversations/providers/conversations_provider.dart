import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/conversations_repository.dart';
import '../data/models/conversation_detail.dart';
import '../data/models/conversation_session.dart';

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationSession>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier
    extends AsyncNotifier<List<ConversationSession>> {
  @override
  Future<List<ConversationSession>> build() {
    return ref.read(conversationsRepositoryProvider).listSessions();
  }

  Future<ConversationSession> createSession() async {
    final session =
        await ref.read(conversationsRepositoryProvider).createSession();
    state = AsyncData([session, ...state.valueOrNull ?? []]);
    return session;
  }

  Future<void> deleteSession(int id) async {
    await ref.read(conversationsRepositoryProvider).deleteSession(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((s) => s.id != id).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(conversationsRepositoryProvider).listSessions(),
    );
  }
}

final conversationDetailProvider =
    FutureProvider.autoDispose.family<ConversationDetail, int>((ref, id) {
  return ref.read(conversationsRepositoryProvider).getSession(id);
});
