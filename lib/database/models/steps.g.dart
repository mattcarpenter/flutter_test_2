// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Step _$StepFromJson(Map<String, dynamic> json) => Step(
      id: json['id'] as String,
      type: json['type'] as String,
      text: json['text'] as String,
      note: json['note'] as String?,
      timerDurationSeconds: (json['timerDurationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StepToJson(Step instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'text': instance.text,
      'note': instance.note,
      'timerDurationSeconds': instance.timerDurationSeconds,
    };
