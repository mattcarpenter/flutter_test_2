import 'dart:convert';

import 'package:drift/drift.dart';

class StringListTypeConverter extends TypeConverter<List<String>, String> {
  @override
  List<String> fromSql(String fromDb) {
    try {
      return List<String>.from(jsonDecode(fromDb));
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}
