/// Схема адресов приложения (ADR-0005).
///
/// Path-стратегия, без `#`. Любой экран открывается по прямой ссылке
/// и переживает F5 — это требование одновременно к фронтенду и к конфигурации
/// Caddy, который обязан отдавать `index.html` на неизвестный путь.
///
/// Префикс `/api` зарезервирован: ни один пользовательский маршрут не может
/// с него начинаться.
sealed class AppRoutes {
  /// Список моих проектов. Корень приложения.
  static const projects = '/';

  /// Имя маршрута списка проектов.
  static const projectsName = 'projects';

  /// Проект: очереди, участники, настройки. Адресуется slug'ом, а не id —
  /// ссылку на проект копируют и отправляют людям.
  static const project = '/projects/:slug';

  /// @nodoc
  static const projectName = 'project';

  /// Список задач очереди. Ключ очереди глобально уникален и неизменяем,
  /// поэтому адрес не ломается при переименовании проекта.
  static const queue = '/queues/:key';

  /// @nodoc
  static const queueName = 'queue';

  /// Задача. Адресуется ключом: он уникален глобально, проект в пути не нужен.
  static const issue = '/issues/:key';

  /// @nodoc
  static const issueName = 'issue';

  /// Приём приглашения в проект. Вне оболочки: пользователь ещё не внутри.
  static const invite = '/invite/:token';

  /// @nodoc
  static const inviteName = 'invite';

  /// Профиль и настройки уведомлений.
  static const profile = '/me';

  /// @nodoc
  static const profileName = 'profile';

  /// Управление списком доступа. Виден только владельцу трекера.
  static const access = '/me/access';

  /// @nodoc
  static const accessName = 'access';

  /// Центр уведомлений.
  static const notifications = '/notifications';

  /// @nodoc
  static const notificationsName = 'notifications';

  /// Вход. Вне оболочки.
  static const login = '/login';

  /// @nodoc
  static const loginName = 'login';

  /// Доступ к трекеру закрыт. Вне оболочки.
  static const accessDenied = '/access-denied';

  /// @nodoc
  static const accessDeniedName = 'accessDenied';

  /// Адрес проекта по slug'у.
  static String projectPath(String slug) => '/projects/$slug';

  /// Адрес очереди по ключу.
  static String queuePath(String key) => '/queues/$key';

  /// Адрес задачи по ключу вида `DEV-42`.
  static String issuePath(String key) => '/issues/$key';

  /// Адрес приглашения по токену.
  static String invitePath(String token) => '/invite/$token';
}

/// Проверки параметров маршрутов.
///
/// Ключ, не подходящий под формат, — это не ошибка сервера, а опечатка
/// в адресной строке: такой путь ведёт на «не найдено», а не на запрос к API.
sealed class RouteParams {
  /// Ключ задачи: префикс очереди заглавными латинскими, дефис, номер.
  static final issueKey = RegExp(r'^[A-Z][A-Z0-9]{0,9}-\d{1,7}$');

  /// Ключ очереди: только префикс.
  static final queueKey = RegExp(r'^[A-Z][A-Z0-9]{0,9}$');

  /// Slug проекта: строчные латинские, цифры и дефисы.
  static final projectSlug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  /// Токен приглашения.
  static final inviteToken = RegExp(r'^[A-Za-z0-9_-]{16,128}$');
}
