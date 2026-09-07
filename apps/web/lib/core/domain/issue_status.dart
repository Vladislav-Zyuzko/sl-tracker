/// Статус задачи — пять значений MVP (`docs/design/system.md`, 4).
///
/// Порядок объявления — это и есть порядок показа в любых списках и меню:
/// открыт → в работе → ревью → тестирование → закрыт. Менять его нельзя.
///
/// Бэкенд отдаёт [code]; палитру и иконку выбирает клиент.
enum IssueStatus {
  /// Открыт.
  open('open', 'Открыт'),

  /// В работе.
  inProgress('in_progress', 'В работе'),

  /// Ревью.
  review('review', 'Ревью'),

  /// Тестирование.
  testing('testing', 'Тестирование'),

  /// Закрыт.
  closed('closed', 'Закрыт');

  /// @nodoc
  const IssueStatus(this.code, this.label);

  /// Код статуса в API.
  final String code;

  /// Название статуса в интерфейсе. Показывается всегда: цвет — четвёртый
  /// канал смысла после текста, иконки и позиции, и один он не работает.
  final String label;

  /// Разбирает код, пришедший от сервера.
  ///
  /// Возвращает `null` для незнакомого кода: клиент не должен падать
  /// на статусе, о котором ещё не знает.
  static IssueStatus? tryParse(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }

    return null;
  }
}
