import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('ConverterEntry')
class Converters extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  TextColumn get term => text()();                 // Associated normalized term
  TextColumn get fromUnit => text()();             // Recipe-side source unit (e.g., cup)
  TextColumn get toBaseUnit => text()();           // Base unit (g, ml, count)
  RealColumn get conversionFactor => real()();     // Factor to convert from recipe unit to base unit
  BoolColumn get isApproximate =>
      boolean().withDefault(const Constant(false))();  // Flag if conversion is approximate
  TextColumn get notes => text().nullable()();     // Optional notes about the conversion

  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();

  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
