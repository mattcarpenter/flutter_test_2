# Household Data Synchronization & Security Strategy

## Overview

This document outlines the data synchronization approach and security considerations for household management functionality. It clarifies that there is NO automatic data migration when users join or leave households, and explains how PowerSync handles data access based on membership.

## Data Synchronization Strategy

### Core Principle: No Automatic Data Migration

When users join households, their existing personal data (where householdId = null) remains personal. Only new data created after joining will have the householdId set and be shared with the household.

### 1. How PowerSync Handles Data Synchronization

#### Tables with Household Support
These tables have both `user_id` and `household_id` columns:
- `recipes` - Recipes created with householdId are shared
- `recipe_folders` - Folders created with householdId are shared
- `pantry_items` - Pantry items created with householdId are shared
- `shopping_lists` - Shopping lists created with householdId are shared
- `meal_plans` - Meal plans created with householdId are shared
- `converters` - Unit converters created with householdId are shared

#### PowerSync Sync Rules
```yaml
# PowerSync automatically syncs data based on membership
bucket_definitions:
  household_data:
    parameters:
      - SELECT id as user_id FROM auth.users WHERE id = token_parameters.user_id
      - SELECT household_id FROM household_members 
        WHERE user_id = token_parameters.user_id AND is_active = 1
    data:
      - SELECT * FROM recipes 
        WHERE (user_id = bucket.user_id AND household_id IS NULL) 
        OR household_id = bucket.household_id
      # Similar rules for other tables...
```

#### Key Points:
- PowerSync automatically includes household data when a user is an active member
- No manual data migration needed - it's all handled by sync rules
- When user leaves household, they lose access to household data immediately
- Personal data (householdId = null) is never shared

### 2. Household Membership Workflows

#### 2.1 Join Household Process

**Trigger:** User accepts household invitation

**Process:**
```sql
-- Simple membership creation - no data migration
BEGIN;

-- Step 1: Create household membership
INSERT INTO household_members (
    id, household_id, user_id, role, is_active, joined_at
) VALUES (
    gen_random_uuid(), $household_id, $user_id, 'member', 1, 
    extract(epoch from now()) * 1000
);

-- Step 2: Update invitation status
UPDATE household_invites 
SET status = 'accepted', 
    accepted_at = NOW(),
    accepted_by_user_id = $user_id,
    updated_at = NOW()
WHERE invite_code = $invite_code;

COMMIT;
```

**What Happens:**
- User becomes a household member
- PowerSync automatically starts syncing household data to their device
- User's existing personal data remains personal (householdId = null)
- Any NEW data they create will have householdId set

#### 2.2 Leave Household Process

**Trigger:** User leaves household or is removed

**Process:**
```sql
-- Simple membership removal - no data migration
BEGIN;

-- Soft delete membership
UPDATE household_members 
SET is_active = 0, 
    deleted_at = extract(epoch from now()) * 1000,
    updated_at = extract(epoch from now()) * 1000
WHERE user_id = $user_id AND household_id = $household_id;

-- If ownership transfer needed (handled separately)

COMMIT;
```

**What Happens:**
- User loses access to household data immediately
- PowerSync stops syncing household data to their device
- User keeps their personal data (householdId = null)
- Any data they created with householdId stays with the household

### 3. Data Ownership Principles

#### 3.1 How Data Works in Households
- **Personal Data**: Created without householdId, only visible to creator
- **Household Data**: Created with householdId, visible to all household members
- **No Automatic Sharing**: Joining a household doesn't share your existing personal data
- **Creator Ownership**: The user_id field always shows who created the data

#### 3.2 When Users Leave Households
- **Personal Data**: Remains with the user (householdId = null)
- **Household Data**: Stays with the household, user loses access
- **No Data Migration**: PowerSync handles access control automatically
- **Clean Separation**: No complex data ownership transfers needed

## Security Considerations

### 1. Authentication & Authorization

#### 1.1 API Authentication
```typescript
// JWT token validation middleware
async function authenticateUser(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'No authentication token provided' });
  }
  
  try {
    const { data: user, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    
    // Attach user to request for use in handlers
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token validation failed' });
  }
}
```

#### 1.2 Operation Authorization
```typescript
// Household operation authorization
async function authorizeHouseholdOperation(
  userId: string, 
  householdId: string, 
  requiredRole: 'member' | 'admin' | 'owner'
): Promise<boolean> {
  const membership = await db
    .select()
    .from(householdMembers)
    .where(eq(householdMembers.userId, userId))
    .where(eq(householdMembers.householdId, householdId))
    .where(eq(householdMembers.isActive, 1))
    .limit(1);
  
  if (!membership.length) {
    return false;
  }
  
  const userRole = membership[0].role;
  const roleHierarchy = { member: 1, admin: 2, owner: 3 };
  
  return roleHierarchy[userRole] >= roleHierarchy[requiredRole];
}
```

### 2. Row Level Security (RLS) Policies

#### 2.1 Household Invites Policy
```sql
-- Read access: Users can see invites they sent or received
CREATE POLICY "household_invites_read" ON household_invites
FOR SELECT USING (
  invited_by_user_id = auth.uid() OR
  email = auth.email() OR
  accepted_by_user_id = auth.uid()
);

-- No direct insert/update/delete - API only
CREATE POLICY "household_invites_api_only" ON household_invites
FOR INSERT, UPDATE, DELETE USING (false);
```

#### 2.2 Household Members Policy
```sql
-- Read access: Members can see other members of their household
CREATE POLICY "household_members_read" ON household_members
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = auth.uid()
    AND hm.household_id = household_members.household_id
    AND hm.is_active = 1
  )
);

-- No direct modifications - API only
CREATE POLICY "household_members_api_only" ON household_members
FOR INSERT, UPDATE, DELETE USING (false);
```

#### 2.3 Enhanced Data Access Policies
```sql
-- Example: Recipes RLS policy
CREATE POLICY "recipes_access" ON recipes
FOR ALL USING (
  -- Own personal data
  (user_id = auth.uid() AND household_id IS NULL) OR
  -- Household data where user is active member
  (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
);

-- Helper function for household membership check
CREATE OR REPLACE FUNCTION is_household_member(
  target_household_id UUID, 
  user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = target_household_id
    AND user_id = user_id
    AND is_active = 1
    AND deleted_at IS NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Input Validation & Sanitization

#### 3.1 Email Validation
```typescript
import validator from 'validator';

function validateEmail(email: string): boolean {
  return validator.isEmail(email) && email.length <= 254;
}

function sanitizeEmail(email: string): string {
  return validator.normalizeEmail(email.trim().toLowerCase()) || '';
}
```

#### 3.2 Household Name Validation
```typescript
function validateHouseholdName(name: string): boolean {
  const trimmed = name.trim();
  return trimmed.length >= 1 && 
         trimmed.length <= 100 && 
         /^[a-zA-Z0-9\s\-'\.]+$/.test(trimmed);
}
```

#### 3.3 UUID Validation
```typescript
function validateUUID(id: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(id);
}
```

### 4. Rate Limiting & Abuse Prevention

#### 4.1 API Rate Limits
```typescript
import rateLimit from 'express-rate-limit';

// Email invitations
const emailInviteLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 email invites per minute
  message: 'Too many email invitations. Please wait before sending more.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Resend emails
const resendLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1, // 1 resend per 15 minutes per IP
  message: 'Please wait 15 minutes before resending.',
});

// General API operations
const generalLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // 60 requests per minute
  message: 'Too many requests. Please slow down.',
});
```

#### 4.2 Per-User Rate Limiting
```typescript
// Database-backed rate limiting
async function checkUserRateLimit(
  userId: string, 
  operation: string, 
  windowMs: number, 
  maxRequests: number
): Promise<boolean> {
  const windowStart = new Date(Date.now() - windowMs);
  
  const requestCount = await db
    .select({ count: count() })
    .from(apiRequestLogs)
    .where(eq(apiRequestLogs.userId, userId))
    .where(eq(apiRequestLogs.operation, operation))
    .where(gte(apiRequestLogs.createdAt, windowStart));
  
  return requestCount[0].count < maxRequests;
}
```

### 5. Data Privacy & Compliance

#### 5.1 Data Encryption
- **In Transit**: All API communication over HTTPS/TLS 1.3
- **At Rest**: Database encryption via Supabase (AES-256)
- **Sensitive Fields**: Additional encryption for PII if needed

#### 5.2 Audit Logging
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Log household operations
INSERT INTO audit_logs (user_id, action, resource_type, resource_id, new_values)
VALUES ($user_id, 'invite_user', 'household_invite', $invite_id, $invite_data);
```

#### 5.3 Data Retention
```sql
-- Soft delete expired invites after 30 days
UPDATE household_invites 
SET deleted_at = extract(epoch from now()) * 1000
WHERE expires_at < extract(epoch from now() - interval '30 days') * 1000
AND deleted_at IS NULL;

-- Archive old audit logs after 1 year
DELETE FROM audit_logs 
WHERE created_at < NOW() - INTERVAL '1 year';
```

### 6. Security Monitoring

#### 6.1 Suspicious Activity Detection
```typescript
// Monitor for rapid-fire invitations
async function detectInviteSpam(userId: string): Promise<boolean> {
  const recentInvites = await db
    .select({ count: count() })
    .from(householdInvites)
    .where(eq(householdInvites.invitedByUserId, userId))
    .where(gte(householdInvites.createdAt, new Date(Date.now() - 60000))); // 1 minute
  
  return recentInvites[0].count > 10; // More than 10 invites in 1 minute
}

// Monitor for failed authentication attempts
async function detectBruteForce(ip: string): Promise<boolean> {
  const failedAttempts = await redis.get(`failed_auth:${ip}`);
  return parseInt(failedAttempts || '0') > 5; // More than 5 failures
}
```

#### 6.2 Real-time Alerts
```typescript
// Alert on suspicious patterns
async function triggerSecurityAlert(
  type: 'invite_spam' | 'brute_force' | 'data_breach',
  userId: string,
  details: any
): Promise<void> {
  // Log to security monitoring system
  console.warn(`Security Alert: ${type}`, { userId, details });
  
  // Could integrate with services like:
  // - AWS CloudWatch
  // - Datadog
  // - Custom monitoring endpoints
}
```

## Edge Cases & Error Handling

### 1. Concurrent Modifications
- **Optimistic Locking**: Use version fields or updated_at timestamps
- **Retry Logic**: Implement exponential backoff for conflicts
- **User Notification**: Inform users of concurrent changes

### 2. Network Failures
- **Transaction Rollback**: Ensure atomic operations
- **Idempotent APIs**: Safe to retry operations
- **Client Retry**: Automatic retry with backoff

### 3. Orphaned Data Protection
- **Foreign Key Constraints**: Prevent data orphaning
- **Cascade Rules**: Proper handling of dependent data
- **Validation Checks**: Regular data integrity scans

### 4. Membership Failures
- **Failed Invitations**: Clear error messages for users
- **Orphaned Memberships**: Regular cleanup of inactive members
- **Sync Issues**: PowerSync retry mechanisms handle temporary failures

This comprehensive strategy ensures secure, reliable household management while maintaining user privacy and system integrity throughout the household sharing lifecycle.