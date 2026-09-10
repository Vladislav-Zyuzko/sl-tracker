import 'package:flutter_riverpod/misc.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/access/data/access_repository.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/domain/session.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';

/// Профиль для тестов.
MeResponseDto fakeMe({
  String id = 'user-1',
  String displayName = 'Анна Петрова',
  String email = 'anna@yandex.ru',
  bool isInstanceOwner = true,
  bool canManageAccessList = true,
}) => MeResponseDto(
  id: id,
  displayName: displayName,
  email: email,
  avatarUrl: null,
  isInstanceOwner: isInstanceOwner,
  canManageAccessList: canManageAccessList,
  session: MeSessionDto(
    kind: MeSessionDtoKind.cookie,
    expiresAt: DateTime.utc(2026, 12, 31),
  ),
);

/// Запись списка доступа для тестов.
AccessEntryDto fakeEntry({
  String id = 'entry-1',
  String email = 'ivan@yandex.ru',
  AccessEntryDtoSource source = AccessEntryDtoSource.config,
  bool isInstanceOwner = false,
  bool isSelf = false,
  DateTime? createdAt,
}) => AccessEntryDto(
  id: id,
  email: email,
  source: source,
  isInstanceOwner: isInstanceOwner,
  createdAt: createdAt ?? DateTime.utc(2026, 2, 12, 10, 30),
  firstLoginAt: null,
  user: null,
  addedBy: null,
  isSelf: isSelf,
);

/// Подставной репозиторий сессии.
///
/// Реализация через `implements`: настоящий репозиторий — тонкая обёртка над
/// сгенерированным клиентом, и городить ради теста интерфейс поверх интерфейса
/// незачем.
class FakeAuthRepository implements AuthRepository {
  /// @nodoc
  FakeAuthRepository({
    this.meResult,
    this.meFailure,
    this.logoutFailure,
    this.email,
  });

  /// Что вернёт `GET /api/me`.
  MeResponseDto? meResult;

  /// Чем упадёт `GET /api/me`.
  ApiFailure? meFailure;

  /// Чем упадёт выход.
  ApiFailure? logoutFailure;

  /// Адрес, который отдаст обмен тикета. `null` — тикет протух.
  String? email;

  /// Сколько раз спрашивали профиль.
  var meCalls = 0;

  /// Сколько раз выходили.
  var logoutCalls = 0;

  /// Сколько раз меняли тикет — обмен обязан быть ровно один.
  var ticketCalls = 0;

  @override
  Future<MeResponseDto> me() async {
    meCalls++;
    final failure = meFailure;
    if (failure != null) throw failure;

    return meResult!;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    final failure = logoutFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<String?> accessDeniedEmail(String ticket) async {
    ticketCalls++;

    return email;
  }
}

/// Подставной репозиторий списка доступа.
class FakeAccessRepository implements AccessRepository {
  /// @nodoc
  FakeAccessRepository({List<AccessEntryDto>? entries, this.listFailure})
    : entries = entries ?? [];

  /// Записи, которые вернёт список.
  List<AccessEntryDto> entries;

  /// Чем упадёт загрузка списка.
  ApiFailure? listFailure;

  /// Последний переданный поисковый запрос.
  String? lastQuery;

  @override
  Future<AccessEntryListDto> list({String? cursor, String? query}) async {
    lastQuery = query;
    final failure = listFailure;
    if (failure != null) throw failure;

    return AccessEntryListDto(
      items: entries,
      nextCursor: null,
      total: entries.length,
    );
  }

  @override
  Future<AccessEntryDto> add(String email) async {
    final created = fakeEntry(
      id: 'entry-${entries.length + 1}',
      email: email,
      source: AccessEntryDtoSource.manual,
    );
    entries = [created, ...entries];

    return created;
  }

  @override
  Future<AccessEntryDto> setInstanceOwner(
    String id, {
    required bool value,
  }) async {
    final index = entries.indexWhere((entry) => entry.id == id);
    final updated = entries[index].copyWith(isInstanceOwner: value);
    entries = [...entries]..[index] = updated;

    return updated;
  }

  @override
  Future<int> revoke(String id) async {
    entries = entries.where((entry) => entry.id != id).toList();

    return 2;
  }
}

/// Переопределение состояния сессии: пользователь уже внутри.
///
/// Нужно там, где экран поднимается сразу готовым: `GET /api/me` в таком
/// тесте не проверяется, а без сессии экраны за авторизацией показывают
/// не то, что проверяется.
Override signedIn({MeResponseDto? user}) {
  final me = user ?? fakeMe();

  return sessionControllerProvider.overrideWith(
    () => _SignedInSessionController(me),
  );
}

class _SignedInSessionController extends SessionController {
  _SignedInSessionController(this.user);

  final MeResponseDto user;

  @override
  Session build() {
    // Подписка на 401 нужна и здесь: она часть поведения контроллера.
    super.build();

    return Session.authenticated(user);
  }
}
