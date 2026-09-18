import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/core/api/api_exceptions.dart';
import 'package:knowledgevault/core/auth/auth_state.dart';
import 'package:knowledgevault/core/auth/token_storage.dart';
import 'package:knowledgevault/core/cache/local_cache.dart';
import 'package:knowledgevault/features/auth/data/auth_repository.dart';
import 'package:knowledgevault/features/auth/data/models/user_response.dart';
import 'package:knowledgevault/features/auth/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeTokenStorage extends TokenStorage {
  String? token = 'jwt';
  @override
  Future<String?> read() async => token;
  @override
  Future<void> delete() async => token = null;
  @override
  Future<void> save(String t) async => token = t;
}

const _user = UserResponse(id: 3, username: 'awane', email: 'a@b.c');

void main() {
  late MockAuthRepository repo;
  late FakeTokenStorage tokens;
  late AppDatabase db;

  setUp(() {
    repo = MockAuthRepository();
    tokens = FakeTokenStorage();
    db = AppDatabase(executor: NativeDatabase.memory());
  });
  tearDown(() => db.close());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStorageProvider.overrideWithValue(tokens),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('online start signs in and caches the profile', () async {
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    final c = makeContainer();

    expect(await c.read(authProvider.future), isNotNull);
    expect(await db.getKv('current_user'), contains('"awane"'));
    expect(c.read(authStatusProvider), AuthStatus.authenticated);
  });

  test('offline start with a token stays signed in as the cached user',
      () async {
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    await makeContainer().read(authProvider.future); // first run: online

    when(() => repo.getMe()).thenThrow(const NetworkException());
    final offline = makeContainer(); // "restart" with no network

    final user = await offline.read(authProvider.future);
    expect(user?.id, 3);
    expect(offline.read(authStatusProvider), AuthStatus.authenticated);
  });

  test('offline start with no cached profile falls back to signed out',
      () async {
    when(() => repo.getMe()).thenThrow(const NetworkException());
    final c = makeContainer();

    expect(await c.read(authProvider.future), isNull);
    expect(c.read(authStatusProvider), AuthStatus.unauthenticated);
  });

  test('an expired token still signs the user out (not trusted offline)',
      () async {
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    await makeContainer().read(authProvider.future);

    when(() => repo.getMe()).thenThrow(const UnauthorizedException());
    final c = makeContainer();

    expect(await c.read(authProvider.future), isNull);
    expect(tokens.token, isNull);
  });

  test('logout clears cached data but keeps unsent notes', () async {
    when(() => repo.getMe()).thenAnswer((_) async => _user);
    final c = makeContainer();
    await c.read(authProvider.future);
    await db.cacheNoteRows([
      {
        'id': 1,
        'title': 't',
        'content': null,
        'user_id': 3,
        'category_id': null,
        'organization_status': null,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      }
    ]);
    await db.enqueueCreateNote(userId: 3, content: 'unsent');

    await c.read(authProvider.notifier).logout();

    expect(await db.getCachedNoteRows(), isEmpty);
    expect(await db.getKv('current_user'), isNull);
    expect(await db.getPendingOps(3), hasLength(1));
  });
}
