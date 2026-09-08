import 'dart:async';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/invites/data/invitations_repository.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';

/// Проект для тестов.
ProjectDto fakeProject({
  String id = 'project-1',
  String slug = 'sweet-limit',
  String name = 'Sweet Limit',
  String? description = 'Мобильное приложение для команды',
  String? coverUrl,
  ProjectDtoRole role = ProjectDtoRole.admin,
  int memberCount = 3,
  List<ProjectMemberPreviewDto>? members,
}) => ProjectDto(
  id: id,
  slug: slug,
  name: name,
  description: description,
  coverUrl: coverUrl,
  role: role,
  memberCount: memberCount,
  members:
      members ??
      const [
        ProjectMemberPreviewDto(
          id: 'user-1',
          displayName: 'Анна Иванова',
          avatarUrl: null,
          role: ProjectMemberPreviewDtoRole.admin,
        ),
      ],
  createdAt: DateTime.utc(2026, 2, 12),
  updatedAt: DateTime.utc(2026, 2, 12),
);

/// Участник проекта для тестов.
ProjectMemberDto fakeMember({
  String userId = 'user-1',
  String displayName = 'Анна Иванова',
  String email = 'anna@yandex.ru',
  ProjectMemberDtoRole role = ProjectMemberDtoRole.admin,
  bool isSelf = false,
  DateTime? joinedAt,
}) => ProjectMemberDto(
  userId: userId,
  displayName: displayName,
  email: email,
  avatarUrl: null,
  role: role,
  joinedAt: joinedAt ?? DateTime.utc(2026, 2, 12),
  isSelf: isSelf,
);

/// Приглашение для тестов.
InvitationDto fakeInvitation({
  String id = 'invite-1',
  InvitationDtoRole role = InvitationDtoRole.member,
  InvitationDtoState state = InvitationDtoState.active,
  InvitationDtoLifetimeDays lifetimeDays = InvitationDtoLifetimeDays.value7,
  String? url = 'https://tracker.example/invite/token-1234567890123456',
  DateTime? expiresAt,
  DateTime? revokedAt,
  int acceptedCount = 2,
}) => InvitationDto(
  id: id,
  role: role,
  state: state,
  url: url,
  lifetimeDays: lifetimeDays,
  expiresAt: expiresAt ?? DateTime.utc(2026, 2, 19),
  revokedAt: revokedAt,
  createdAt: DateTime.utc(2026, 2, 12),
  createdBy: const InvitationAuthorDto(
    id: 'user-1',
    displayName: 'Анна Иванова',
  ),
  acceptedCount: acceptedCount,
);

/// Предпросмотр приглашения для тестов.
InvitationPreviewDto fakeInvitationPreview({
  String projectName = 'Sweet Limit',
  String projectSlug = 'sweet-limit',
  String? coverUrl,
  InvitationPreviewDtoRole role = InvitationPreviewDtoRole.member,
  bool alreadyMember = false,
}) => InvitationPreviewDto(
  projectName: projectName,
  projectSlug: projectSlug,
  coverUrl: coverUrl,
  role: role,
  alreadyMember: alreadyMember,
);

/// Подставной репозиторий проектов.
///
/// Реализация через `implements`: настоящий репозиторий — тонкая обёртка над
/// сгенерированным клиентом, и городить ради теста интерфейс поверх интерфейса
/// незачем.
class FakeProjectsRepository implements ProjectsRepository {
  /// @nodoc
  FakeProjectsRepository({List<ProjectDto>? projects, this.listFailure})
    : projects = projects ?? [];

  /// Что вернёт список.
  List<ProjectDto> projects;

  /// Чем упадёт список.
  ApiFailure? listFailure;

  /// Пока не завершён, список «грузится»: единственный способ увидеть
  /// состояние загрузки в тесте, где подставной репозиторий отвечает
  /// мгновенно.
  Completer<void>? gate;

  /// Чем упадёт чтение одного проекта.
  ApiFailure? getFailure;

  /// Участники, которых вернёт [members].
  List<ProjectMemberDto> memberList = [];

  /// Чем упадёт список участников.
  ApiFailure? membersFailure;

  /// Чем упадёт смена роли.
  ApiFailure? changeRoleFailure;

  /// Сколько задач осталось без исполнителя после исключения.
  int unassignedIssues = 3;

  /// Что вернёт смена короткого имени. `null` — то же, что запросили.
  String? changedSlug;

  /// Обложка, которую вернёт загрузка.
  String? uploadedCoverUrl = 'https://storage.example/cover-signed';

  /// Последний загруженный файл.
  PickedFile? lastUploadedFile;

  /// Какие проекты удаляли.
  final removedProjects = <String>[];

  @override
  Future<ProjectListDto> list({String? cursor}) async {
    await gate?.future;
    final failure = listFailure;
    if (failure != null) throw failure;

    return ProjectListDto(
      items: projects,
      nextCursor: null,
      total: projects.length,
    );
  }

  @override
  Future<ProjectDto> bySlug(String slug) async {
    final failure = getFailure;
    if (failure != null) throw failure;

    return projects.firstWhere(
      (project) => project.slug == slug,
      orElse: () => projects.isEmpty ? fakeProject(slug: slug) : projects.first,
    );
  }

  @override
  Future<ProjectDto> create({required String name, String? description}) async {
    // Сервер добавил суффикс из-за коллизии: ровно тот случай, когда
    // клиентский предпросмотр адреса расходится с итогом (D-35).
    final created = fakeProject(
      id: 'project-${projects.length + 1}',
      slug: 'sladkiy-limit-2',
      name: name,
      description: description,
    );
    projects = [...projects, created];

    return created;
  }

  @override
  Future<ProjectDto> update(
    String slug, {
    required String name,
    required String description,
  }) async => _store(
    (await bySlug(slug)).copyWith(
      name: name,
      description: description.isEmpty ? null : description,
    ),
  );

  @override
  Future<ProjectDto> changeSlug(String slug, String newSlug) async =>
      _store((await bySlug(slug)).copyWith(slug: changedSlug ?? newSlug));

  @override
  Future<void> remove(String slug) async => removedProjects.add(slug);

  @override
  Future<ProjectDto> uploadCover(String slug, PickedFile file) async {
    lastUploadedFile = file;

    return _store((await bySlug(slug)).copyWith(coverUrl: uploadedCoverUrl));
  }

  @override
  Future<ProjectDto> removeCover(String slug) async =>
      _store((await bySlug(slug)).copyWith(coverUrl: null));

  /// Изменение сохраняется, как на сервере.
  ///
  /// Иначе после смены короткого имени экран уходит по новому адресу,
  /// не находит там проект, получает старый — и адрес прыгает туда-обратно.
  /// Ровно это и всплыло в тесте.
  ProjectDto _store(ProjectDto project) {
    final index = projects.indexWhere((item) => item.id == project.id);
    projects = [...projects];
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }

    return project;
  }

  @override
  Future<ProjectMemberListDto> members(String slug, {String? cursor}) async {
    final failure = membersFailure;
    if (failure != null) throw failure;

    return ProjectMemberListDto(
      items: memberList,
      nextCursor: null,
      total: memberList.length,
    );
  }

  @override
  Future<ProjectMemberDto> changeMemberRole(
    String slug,
    String userId,
    SLRole role,
  ) async {
    final failure = changeRoleFailure;
    if (failure != null) throw failure;

    return memberList
        .firstWhere((member) => member.userId == userId)
        .copyWith(
          role: switch (role) {
            SLRole.admin => ProjectMemberDtoRole.admin,
            SLRole.member => ProjectMemberDtoRole.member,
            SLRole.reader => ProjectMemberDtoRole.reader,
          },
        );
  }

  @override
  Future<int> removeMember(String slug, String userId) async {
    memberList = memberList.where((member) => member.userId != userId).toList();

    return unassignedIssues;
  }
}

/// Подставной репозиторий приглашений.
class FakeInvitationsRepository implements InvitationsRepository {
  /// @nodoc
  FakeInvitationsRepository({
    List<InvitationDto>? invitations,
    this.previewResult,
    this.previewFailure,
    this.acceptFailure,
  }) : invitations = invitations ?? [];

  /// Приглашения проекта.
  List<InvitationDto> invitations;

  /// Что вернёт предпросмотр по токену.
  InvitationPreviewDto? previewResult;

  /// Чем упадёт предпросмотр.
  ApiFailure? previewFailure;

  /// Пока не завершён, предпросмотр «проверяется»: иначе состояние загрузки
  /// в тесте не увидеть — подставной репозиторий отвечает мгновенно.
  Completer<void>? gate;

  /// Чем упадёт вступление.
  ApiFailure? acceptFailure;

  /// Сколько раз вступали.
  var acceptCalls = 0;

  @override
  Future<InvitationListDto> list(String slug, {String? cursor}) async =>
      InvitationListDto(
        items: invitations,
        nextCursor: null,
        total: invitations.length,
      );

  @override
  Future<InvitationDto> create(
    String slug, {
    required SLRole role,
    required CreateInvitationDtoExpiresInDays expiresInDays,
  }) async {
    final created = fakeInvitation(
      id: 'invite-${invitations.length + 1}',
      role: role == SLRole.reader
          ? InvitationDtoRole.reader
          : InvitationDtoRole.member,
    );
    invitations = [created, ...invitations];

    return created;
  }

  @override
  Future<InvitationDto> revoke(String slug, String id) async {
    final revoked = invitations
        .firstWhere((invitation) => invitation.id == id)
        .copyWith(
          state: InvitationDtoState.revoked,
          url: null,
          revokedAt: DateTime.utc(2026, 2, 14),
        );

    invitations = [
      for (final invitation in invitations)
        if (invitation.id == id) revoked else invitation,
    ];

    return revoked;
  }

  @override
  Future<InvitationPreviewDto> preview(String token) async {
    await gate?.future;
    final failure = previewFailure;
    if (failure != null) throw failure;

    return previewResult ?? fakeInvitationPreview();
  }

  @override
  Future<AcceptInvitationResultDto> accept(String token) async {
    acceptCalls++;
    final failure = acceptFailure;
    if (failure != null) throw failure;

    return AcceptInvitationResultDto(
      projectSlug: previewResult?.projectSlug ?? 'sweet-limit',
      role: AcceptInvitationResultDtoRole.member,
      alreadyMember: false,
    );
  }
}
