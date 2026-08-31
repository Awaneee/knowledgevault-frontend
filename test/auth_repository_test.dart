import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/core/api/api_exceptions.dart';
import 'package:knowledgevault/features/auth/data/auth_repository.dart';
import 'package:knowledgevault/features/auth/data/models/login_request.dart';
import 'package:knowledgevault/features/auth/data/models/token_response.dart';
import 'package:knowledgevault/features/auth/data/models/user_response.dart';
import 'package:mocktail/mocktail.dart';

// ── Mock Dio ──────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

Response<T> _resp<T>(T data, {int statusCode = 200}) => Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioErr(int status) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        statusCode: status,
        data: {'detail': 'error'},
        requestOptions: RequestOptions(path: ''),
      ),
      type: DioExceptionType.badResponse,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockDio dio;
  late AuthRepository repo;

  setUp(() {
    dio = MockDio();
    repo = AuthRepository(dio);
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('AuthRepository.login', () {
    test('returns TokenResponse on 200', () async {
      when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => _resp({
          'access_token': 'tok123',
          'token_type': 'bearer',
        }),
      );

      final result = await repo.login(
          const LoginRequest(email: 'a@b.com', password: 'pass'));

      expect(result, isA<TokenResponse>());
      expect(result.accessToken, equals('tok123'));
    });

    test('throws UnauthorizedException on 401', () async {
      when(() => dio.post(any(), data: any(named: 'data')))
          .thenThrow(_dioErr(401));

      await expectLater(
        () => repo.login(
            const LoginRequest(email: 'a@b.com', password: 'wrong')),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws RateLimitException on 429', () async {
      when(() => dio.post(any(), data: any(named: 'data')))
          .thenThrow(_dioErr(429));

      await expectLater(
        () => repo.login(
            const LoginRequest(email: 'a@b.com', password: 'pass')),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  group('AuthRepository.getMe', () {
    test('returns UserResponse on 200', () async {
      when(() => dio.get(any())).thenAnswer(
        (_) async => _resp({
          'id': 1,
          'username': 'awane',
          'email': 'a@b.com',
        }),
      );

      final result = await repo.getMe();
      expect(result, isA<UserResponse>());
      expect(result.username, equals('awane'));
    });

    test('throws UnauthorizedException on 401', () async {
      when(() => dio.get(any())).thenThrow(_dioErr(401));

      await expectLater(
        () => repo.getMe(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
