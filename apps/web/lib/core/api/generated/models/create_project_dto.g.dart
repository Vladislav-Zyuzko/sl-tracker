// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateProjectDto _$CreateProjectDtoFromJson(Map<String, dynamic> json) =>
    _CreateProjectDto(
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreateProjectDtoToJson(_CreateProjectDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
