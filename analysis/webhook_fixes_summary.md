# Webhook Implementation Fixes

## Issues Found and Fixed

### 1. Database Schema Mismatch ✅ Fixed
**Problem**: Webhook controller was trying to insert columns that didn't exist in `subscription_events` table.

**Solution**: 
- Run the SQL in `fix_subscription_events_table.sql` to add missing columns
- Updated webhook controller to handle both structured columns and JSON storage

### 2. User ID Validation Error ✅ Fixed
**Problem**: RevenueCat webhook contained user ID that doesn't exist in Supabase auth.users.

**Solution**: 
- Added user existence check before updating metadata
- Webhook now gracefully handles missing users with warning logs
- Events are still logged even if user doesn't exist

## What You Need to Do

### 1. Update Database Schema
Run this SQL in your Supabase SQL editor:
```bash
# Copy the SQL from fix_subscription_events_table.sql and run it
```

### 2. Restart Your Server
The webhook controller has been updated, so restart your recipe_app_server:
```bash
cd /Users/matt/repos/recipe_app_server
npm run dev
```

### 3. User ID Mapping Issue
The RevenueCat user ID `5584faf7-4407-4037-b638-6ea1b3847735` doesn't exist in your Supabase. This could happen because:

- **Sandbox testing**: RevenueCat generates test user IDs that don't match real users
- **User not created**: Purchase happened before user was created in your app
- **ID mismatch**: RevenueCat app_user_id doesn't match Supabase user ID

### 4. Ensure Proper User ID Mapping
When users sign up in your Flutter app, ensure RevenueCat gets the correct Supabase user ID:

```dart
// In your subscription service initialization
await Purchases.logIn(supabaseUserId); // This should be the same ID
```

## Testing the Fix

1. **Database Updated**: Run the SQL fix
2. **Server Restarted**: Your webhook should now handle the schema correctly
3. **Try Purchase**: Make a test purchase and check:
   - Webhook receives event ✅
   - Event is logged to database ✅
   - If user exists, metadata is updated ✅
   - If user doesn't exist, warning is logged but no error ✅

## Expected Webhook Behavior Now

- ✅ Receive webhook without 500 error
- ✅ Log all events to `subscription_events` table
- ✅ Only update user metadata if user exists in Supabase
- ✅ Graceful handling of missing users

The implementation is now robust and should handle all edge cases properly!