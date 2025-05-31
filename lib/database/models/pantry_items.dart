import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

// Stock status enum for pantry items
enum StockStatus {
  outOfStock, // 0 - Red
  lowStock,   // 1 - Yellow
  inStock     // 2 - Green
}

// Custom type converter for StockStatus enum
class StockStatusConverter extends TypeConverter<StockStatus, int> {
  const StockStatusConverter();

  @override
  StockStatus fromSql(int fromDb) {
    return StockStatus.values[fromDb];
  }

  @override
  int toSql(StockStatus value) {
    return value.index;
  }
}

@DataClassName('PantryItemEntry')
class PantryItems extends Table {
  TextColumn get id         => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  TextColumn get name       => text()();                     // "Kewpie Mayo"
  // Changed from boolean to enum using IntColumn with TypeConverter
  IntColumn get stockStatus => integer()
    .map(const StockStatusConverter())
    .withDefault(const Constant(2))(); // Default to IN_STOCK (index 2)
  
  BoolColumn get isStaple => boolean().withDefault(const Constant(false))();
  BoolColumn get isCanonicalised => boolean().withDefault(const Constant(false))();
  
  // No longer using inStock field - completely replaced by stockStatus
  
  TextColumn  get userId    => text().nullable()();                     // or householdId if multi‑tenant
  TextColumn  get householdId => text().nullable()();

  // Pricing and quantity information
  TextColumn get unit       => text().nullable()();           // Sale unit (e.g., pack, bulb, can)
  RealColumn get quantity   => real().nullable()();           // Number of sale units
  TextColumn get baseUnit   => text().nullable()();           // Base unit (g, ml, count)
  RealColumn get baseQuantity => real().nullable()();         // Quantity in base unit
  RealColumn get price      => real().nullable()();           // Sale price

  IntColumn   get createdAt => integer().nullable()();
  IntColumn   get updatedAt => integer().nullable()();
  IntColumn   get deletedAt => integer().nullable()();

  TextColumn get terms => text().nullable().map(const PantryItemTermListConverter())();
  TextColumn get category => text().nullable()();
}