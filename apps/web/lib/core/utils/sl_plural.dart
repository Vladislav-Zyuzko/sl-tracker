/// Склонение существительного при числительном.
///
/// Без `intl`: пакет тянет данные локалей ради одной функции, а локаль в MVP
/// одна — русская (`core/utils/sl_date_format.dart` заведён по той же
/// причине). «1 задача», «3 задачи», «12 задач» — иначе интерфейс говорит
/// «12 задача», и это видно всем.
sealed class SLPlural {
  /// Нужная форма слова для [count].
  static String of(
    int count, {
    required String one,
    required String few,
    required String many,
  }) {
    final mod100 = count.abs() % 100;
    if (mod100 >= 11 && mod100 <= 14) return many;

    return switch (count.abs() % 10) {
      1 => one,
      2 || 3 || 4 => few,
      _ => many,
    };
  }

  /// Число вместе со словом: «12 задач».
  static String count(
    int count, {
    required String one,
    required String few,
    required String many,
  }) => '$count ${of(count, one: one, few: few, many: many)}';

  /// «12 задач».
  static String issues(int count) =>
      SLPlural.count(count, one: 'задача', few: 'задачи', many: 'задач');

  /// «5 участников».
  static String members(int count) => SLPlural.count(
    count,
    one: 'участник',
    few: 'участника',
    many: 'участников',
  );

  /// «7 дней».
  static String days(int count) =>
      SLPlural.count(count, one: 'день', few: 'дня', many: 'дней');

  /// «12 символов».
  static String characters(int count) =>
      SLPlural.count(count, one: 'символ', few: 'символа', many: 'символов');

  /// «3 проекта».
  static String projects(int count) =>
      SLPlural.count(count, one: 'проект', few: 'проекта', many: 'проектов');
}
