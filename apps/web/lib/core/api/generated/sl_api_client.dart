// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/access_client.dart';
import 'clients/auth_client.dart';
import 'clients/health_client.dart';
import 'clients/projects_client.dart';
import 'clients/invitations_client.dart';
import 'clients/notifications_client.dart';
import 'clients/queues_client.dart';
import 'clients/issues_client.dart';
import 'clients/mentions_client.dart';
import 'clients/comments_client.dart';
import 'clients/attachments_client.dart';

/// SL Tracker API `v0.1.0`.
///
/// HTTP API трекера задач SL Tracker. Единственный источник правды по контракту: файл генерируется из кода, руками не редактируется.
class SlApiClient {
  SlApiClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  AccessClient? _access;
  AuthClient? _auth;
  HealthClient? _health;
  ProjectsClient? _projects;
  InvitationsClient? _invitations;
  NotificationsClient? _notifications;
  QueuesClient? _queues;
  IssuesClient? _issues;
  MentionsClient? _mentions;
  CommentsClient? _comments;
  AttachmentsClient? _attachments;

  AccessClient get access => _access ??= AccessClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  HealthClient get health => _health ??= HealthClient(_dio, baseUrl: _baseUrl);

  ProjectsClient get projects =>
      _projects ??= ProjectsClient(_dio, baseUrl: _baseUrl);

  InvitationsClient get invitations =>
      _invitations ??= InvitationsClient(_dio, baseUrl: _baseUrl);

  NotificationsClient get notifications =>
      _notifications ??= NotificationsClient(_dio, baseUrl: _baseUrl);

  QueuesClient get queues => _queues ??= QueuesClient(_dio, baseUrl: _baseUrl);

  IssuesClient get issues => _issues ??= IssuesClient(_dio, baseUrl: _baseUrl);

  MentionsClient get mentions =>
      _mentions ??= MentionsClient(_dio, baseUrl: _baseUrl);

  CommentsClient get comments =>
      _comments ??= CommentsClient(_dio, baseUrl: _baseUrl);

  AttachmentsClient get attachments =>
      _attachments ??= AttachmentsClient(_dio, baseUrl: _baseUrl);
}
