import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/features/realtime/presentation/realtime_providers.dart';

/// Живые обновления состава участников проекта (US-23, D-26).
///
/// Провайдер ничего не возвращает: его дело — держать подписку, пока вкладка
/// участников открыта, и перечитывать список, когда состав меняется.
/// Экран его `watch`-ит, и этим всё сказано.
///
/// Подписка по короткому имени из адреса: **прежнее имя проекта тоже
/// работает** (US-18), а канонический ярлык возвращает сервер — сравнением
/// занимается клиент живых обновлений, а не экран.
final projectMembersRealtimeProvider = Provider.family<void, String>((
  ref,
  slug,
) {
  listenRealtimeTopic(ref, RealtimeTopics.project(slug), (signal) {
    switch (signal) {
      case RealtimeEvent():
        // Событие несёт только `userId` и роль. Имя, аватар и порядок строк
        // собирает сервер, поэтому список перечитывается целиком, а не
        // достраивается по кусочкам из события.
        if (_membersChanged(signal.event)) _refresh(ref, slug);
      case RealtimeResync():
        _refresh(ref, slug);
      case RealtimeTopicLost():
        // Из проекта могли исключить прямо сейчас: перечитываем проект
        // и показываем то, что вернёт сервер, — «Проект не найден».
        ref.read(projectProvider(slug).notifier).refresh();
    }
  });
}, isAutoDispose: true);

bool _membersChanged(String event) =>
    event == RealtimeEvents.memberJoined ||
    event == RealtimeEvents.memberUpdated ||
    event == RealtimeEvents.memberRemoved;

void _refresh(Ref ref, String slug) =>
    ref.read(projectMembersProvider(slug).notifier).refresh();
