import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/features/access/presentation/access_denied_screen.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_screen.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_screen.dart';
import 'package:sl_tracker_web/features/invites/presentation/invite_accept_screen.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_screen.dart';
import 'package:sl_tracker_web/features/profile/presentation/profile_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_screen.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_screen.dart';
import 'package:sl_tracker_web/features/shell/presentation/app_shell.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Роутер приложения.
///
/// Провайдер, а не глобальная переменная: роутеру понадобится читать состояние
/// сессии, чтобы уводить на вход, и держать это через Riverpod честнее,
/// чем через синглтон.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.projects,
    routes: _routes,
    errorBuilder: (context, state) =>
        _NotFoundScreen(location: state.uri.toString()),
  );
});

/// Заглушка экрана уведомлений: спека есть, данных пока нет.
class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) => const SLEmptyState(
    icon: Icons.notifications_none_rounded,
    title: 'Уведомлений нет',
    description:
        'Сюда попадают уведомления о задачах, '
        'в которых вы участвуете.',
  );
}

final _routes = <RouteBase>[
  // Экраны вне оболочки: пользователь ещё не внутри приложения.
  GoRoute(
    path: AppRoutes.login,
    name: AppRoutes.loginName,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.accessDenied,
    name: AppRoutes.accessDeniedName,
    // Тикет приходит в query, а не в пути: экран открывается и без него —
    // например, когда пользователь вернулся на адрес по истории браузера
    // спустя минуту, и тикет уже протух.
    builder: (context, state) =>
        AccessDeniedScreen(ticket: state.uri.queryParameters['ticket']),
  ),
  GoRoute(
    path: AppRoutes.invite,
    name: AppRoutes.inviteName,
    builder: (context, state) {
      final token = state.pathParameters['token'] ?? '';

      return RouteParams.inviteToken.hasMatch(token)
          ? InviteAcceptScreen(token: token)
          : const _InvalidInviteScreen();
    },
  ),

  // Устаревшие и «интуитивные» адреса. Пользователь вполне может набрать
  // /projects руками — приводим к каноническому виду, а не отдаём 404.
  GoRoute(path: '/projects', redirect: (_, _) => AppRoutes.projects),
  GoRoute(path: '/profile', redirect: (_, _) => AppRoutes.profile),
  GoRoute(path: '/access', redirect: (_, _) => AppRoutes.access),

  ShellRoute(
    builder: (context, state, child) => AppShell(child: child),
    routes: [
      GoRoute(
        path: AppRoutes.projects,
        name: AppRoutes.projectsName,
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.project,
        name: AppRoutes.projectName,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';

          return RouteParams.projectSlug.hasMatch(slug)
              ? ProjectScreen(slug: slug)
              : _NotFoundScreen(location: state.uri.toString());
        },
      ),
      GoRoute(
        path: AppRoutes.queue,
        name: AppRoutes.queueName,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';

          return RouteParams.queueKey.hasMatch(key)
              ? QueueIssuesScreen(queueKey: key)
              : _NotFoundScreen(location: state.uri.toString());
        },
      ),
      GoRoute(
        path: AppRoutes.issue,
        name: AppRoutes.issueName,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';

          // Ключ, не подходящий под формат, — это опечатка в адресной строке,
          // а не отсутствующая задача: к API за ним не ходим.
          return RouteParams.issueKey.hasMatch(key)
              ? IssueScreen(issueKey: key)
              : const _IssueNotFoundScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        builder: (context, state) => const _NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'access',
            name: AppRoutes.accessName,
            builder: (context, state) => const AccessListScreen(),
          ),
        ],
      ),
    ],
  ),
];

/// Неизвестный адрес.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SLErrorState(
      title: 'Страница не найдена',
      description: 'Проверьте адрес: возможно, в ссылке опечатка.',
      actionLabel: 'К списку проектов',
      onAction: () => GoRouter.of(context).go(AppRoutes.projects),
      details: location,
    ),
  );
}

/// Задача не найдена.
///
/// Текст намеренно не различает «удалена» и «нет доступа»: иначе экран
/// раскрывал бы существование задачи из чужого проекта.
class _IssueNotFoundScreen extends StatelessWidget {
  const _IssueNotFoundScreen();

  @override
  Widget build(BuildContext context) => SLErrorState(
    title: 'Задача не найдена',
    description:
        'Возможно, она удалена, или у вас нет доступа '
        'к её проекту.',
    actionLabel: 'К списку проектов',
    onAction: () => GoRouter.of(context).go(AppRoutes.projects),
  );
}

/// Приглашение с непригодным токеном.
class _InvalidInviteScreen extends StatelessWidget {
  const _InvalidInviteScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SLErrorState(
      title: 'Ссылка приглашения не подходит',
      description:
          'Проверьте, что скопировали ссылку целиком, '
          'или попросите отправить её ещё раз.',
      actionLabel: null,
      onAction: null,
    ),
  );
}
