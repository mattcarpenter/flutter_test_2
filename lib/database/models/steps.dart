import 'package:json_annotation/json_annotation.dart';

part 'steps.g.dart';

@JsonSerializable()
class Step {
  final String id;
  final String type; // "step", "section", "timer"
  final String text;
  final String? note;
  final int? timerDurationSeconds;

  Step({
    required this.id,
    required this.type,
    required this.text,
    this.note,
    this.timerDurationSeconds,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    // Handle potential null values from imported/synced data
    return Step(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'step',
      text: json['text'] as String? ?? '',
      note: json['note'] as String?,
      timerDurationSeconds: (json['timerDurationSeconds'] as num?)?.toInt(),
    );
  }
  Map<String, dynamic> toJson() => _$StepToJson(this);

  Step copyWith({
    String? id,
    String? type,
    String? text,
    String? note,
    int? timerDurationSeconds,
  }) {
    return Step(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      note: note ?? this.note,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
    );
  }
}
