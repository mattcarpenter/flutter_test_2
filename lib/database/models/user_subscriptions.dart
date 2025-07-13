import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

// Subscription status enum
enum SubscriptionStatus {
  none,      // 0 - No subscription
  active,    // 1 - Active subscription (includes trial periods)
  cancelled, // 2 - Cancelled but still valid until expiry
  expired    // 3 - Expired subscription
}

// Custom type converter for SubscriptionStatus enum
class SubscriptionStatusConverter extends TypeConverter<SubscriptionStatus, String> {
  const SubscriptionStatusConverter();

  @override
  SubscriptionStatus fromSql(String fromDb) {
    switch (fromDb) {
      case 'active':
        return SubscriptionStatus.active;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'none':
      default:
        return SubscriptionStatus.none;
    }
  }

  @override
  String toSql(SubscriptionStatus value) {
    switch (value) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.none:
      default:
        return 'none';
    }
  }
}

@DataClassName('UserSubscriptionEntry')
class UserSubscriptions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};
  
  // User and household relationship
  TextColumn get userId => text()();
  TextColumn get householdId => text().nullable()();
  
  // Subscription status
  TextColumn get status => text()
    .map(const SubscriptionStatusConverter())
    .withDefault(const Constant('none'))();
  
  // Entitlements as JSON array ["plus", "premium"]  
  TextColumn get entitlements => text()
    .map(const StringListTypeConverter())
    .withDefault(const Constant('[]'))();
  
  // Timing columns (Unix timestamps in milliseconds)
  IntColumn get expiresAt => integer().nullable()();
  IntColumn get trialEndsAt => integer().nullable()();
  IntColumn get cancelledAt => integer().nullable()();
  
  // RevenueCat integration
  TextColumn get productId => text().nullable()();
  TextColumn get store => text().nullable()(); // app_store, play_store, stripe
  TextColumn get revenuecatCustomerId => text().nullable()();
  
  // Metadata (Unix timestamps in milliseconds)
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
}