import 'dart:ffi';

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pantry_item_terms.g.dart';

@JsonSerializable()
class PantryItemTerm {
  final String value;
  final String source; // "user", "ai", or "inferred"
  final int sort;

  PantryItemTerm({
    required this.value,
    required this.source,
    required this.sort,
  });

  factory PantryItemTerm.fromJson(Map<String, dynamic> json) =>
      _$PantryItemTermFromJson(json);

  Map<String, dynamic> toJson() => _$PantryItemTermToJson(this);
}
