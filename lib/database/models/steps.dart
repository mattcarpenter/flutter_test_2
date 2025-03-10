import 'package:json_annotation/json_annotation.dart';

part 'steps.g.dart';

@JsonSerializable()
class Step {
  final String type; // "step", "section", "timer"
  final String text;
  final String? note;
  final int? timerDurationSeconds;

  Step({
    required this.type,
    required this.text,
    this.note,
    this.timerDurationSeconds,
  });

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);
  Map<String, dynamic> toJson() => _$StepToJson(this);
}
