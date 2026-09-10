import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/partial_update_interceptor.dart';

/// Прогоняет тело через интерсептор и отдаёт то, что уедет на сервер.
Map<String, dynamic> send(Object? body) {
  final options = apply(RequestOptions(path: '/api/issues/DEV-42', data: body));
  final data = options.data;

  return data is Map<String, dynamic> ? data : <String, dynamic>{};
}

/// Прогоняет запрос через интерсептор.
RequestOptions apply(RequestOptions options) {
  PartialUpdateInterceptor().onRequest(options, RequestInterceptorHandler());

  return options;
}

void main() {
  group('частичное обновление', () {
    test('поля со значением null из тела убираются', () {
      // Ровно тот случай, ради которого интерсептор написан: смена статуса
      // не должна заодно очищать описание и снимать исполнителя.
      final body = send(UpdateIssueDto(statusId: 'status-1').toJson());

      expect(body, {'statusId': 'status-1'});
      expect(body.containsKey('description'), isFalse);
      expect(body.containsKey('assigneeId'), isFalse);
    });

    test('маркер превращается в настоящий null', () {
      final body = send(
        UpdateIssueDto(assigneeId: PartialUpdateInterceptor.explicitNull)
            .toJson(),
      );

      expect(body.containsKey('assigneeId'), isTrue);
      expect(body['assigneeId'], isNull);
    });

    test(r'$unknown у перечисления снимает значение', () {
      // Так выражается «снять оценку сложности»: другого способа сказать
      // «пусто» перечислением у сгенерированной модели нет.
      final body = send(
        UpdateIssueDto(storyPoints: UpdateIssueDtoStoryPoints.$unknown)
            .toJson(),
      );

      expect(body.containsKey('storyPoints'), isTrue);
      expect(body['storyPoints'], isNull);
    });

    test('обычные значения не трогаются', () {
      final body = send(
        UpdateIssueDto(
          title: 'Новое название',
          priority: UpdateIssueDtoPriority.value80,
          storyPoints: UpdateIssueDtoStoryPoints.value8,
        ).toJson(),
      );

      expect(body['title'], 'Новое название');
      expect(body['priority'], 80);
      expect(body['storyPoints'], 8);
    });

    test('пустая строка — это значение, а не отсутствие', () {
      // `description: ''` очищает описание, и выбрасывать его нельзя.
      final body = send(const UpdateIssueDto(description: '').toJson());

      expect(body, {'description': ''});
    });

    test('тело не-Map не трогается', () {
      final options = apply(
        RequestOptions(
          path: '/api/issues/DEV-42/attachments',
          data: FormData(),
        ),
      );

      expect(options.data, isA<FormData>());
    });
  });
}
