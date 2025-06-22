# Household Management Feature Architecture

## Executive Summary

This document provides comprehensive architectural guidance for implementing household creation and member management features in the recipe app. The analysis covers current data behavior, UX patterns, technical implementation approaches, and critical edge cases around data ownership and migration.

## Current State Analysis

### Data Architecture

The app currently supports household sharing through a dual-ownership model:

- **Personal Data**: `userId=A, householdId=null`
- **Household Data**: `userId=A, householdId=B`
- **Data Access**: Repository methods filter by EXACT match on both parameters

### Critical Discovery: No Automatic Data Migration

**The current implementation does NOT automatically share existing personal data when a user joins a household.** Data is only accessible via household sharing if it was originally created with a specific `householdId`.

### Existing Implementation

#### Database Schema
```sql
-- Households table
households: id (UUID), name (text), user_id (UUID owner)

-- Membership table  
household_members: id (UUID), household_id (FK), user_id (FK), is_active (integer)
-- Primary key: {household_id, user_id}

-- Data tables all follow pattern:
recipes: ..., user_id (UUID), household_id (UUID nullable), ...
```

#### Access Control
- **PowerSync Sync Rules**: Sync data where user is active household member
- **RLS Policies**: `is_household_member(household_id, auth.uid())` function checks active membership
- **Local Filtering**: Repository methods require exact `userId` AND `householdId` match

#### Current Code Assets
- Basic household CRUD: `HouseholdRepository`, `HouseholdNotifier`
- Missing: Household member management, invitation system, data migration

#### Proposed Solution:
* When a user joins a household (join or create) we automatically set the `householdId` on all existing personal data where `userId = auth.uid()`
* When a user leaves a household, we automatically set the `householdId` to null on all existing personal data where `userId = auth.uid()`

## UX Architecture & Patterns

### Patterns

#### Invitation Flow Patterns

- Household owner invites user by email address
  - Send an email with link that opens the app if the email is already a registered active user
  - If not registered, link sends user to app store
  - Recipient can see invite in app
  - cases when we dont send a invite:
    - user is already a member of any household
    - user is already invited to any household
    - show an error in this case when trying to invite the user. can be generic and say "User is already invited to a household" or "You've already invited this user" in these cases
- Household owner can also invite members by generating an invite code

Notes:
- Invites will be created by calling an API on our express app
  - On the backend we'll take care of creating the invite in supabase
  - On the backend we'll use the 
- All other operations related to invites will be implemented server-side as well. this includes resending, revoking, and accepting.

### UX Flow

#### Creating a Household
1. **Trigger**: "Household Sharing" button in "more" menu shows new Household Sharing page
2. **Household Sharing page**:
  - initially just 2 sections - "Create Household" (just a button), and "Join with Code" button below
  - If user has household, replace create section with Members section
    - Shows members of household, including owner. chip indicates role (owner or member). 3 dot menu (...) that shows a context menu with a single option: remove member
      - Remove member shows dialog with Cancel/Remove Member buttons to confirm
      - Only household owner can see the 3 dot menu and remove members
      - List is separated into two parts. Top is members in the household, bottom is pending invites
      - The invite record in the db should contain a "display name" and a 3 dot (...) context menu that only the owner can see/use
        - only pending invites are shown (need a column for status i guess)
        - when an invite is created by email, the display name should be set to the email  (if invite was sent via email so maybe we need a col that indicates whether it's email or code invite)
        - when an invite is a created code, we put tne name collected before generating the code in the display name
        - context menu has "Resend Invite" (if sent via email)
          - we should keep a lastSent timestamp in the db and the backend should limit sending to every 15 mins. 
            - show a toast with success/failure
        - context menu has "Revoke Invite" option
          - tapping this shows a confirmation dialog with Cancel/Revoke Invite buttons to confirm
        - context menu has "Copy Invite Code" option
          - copies the invite code to clipboard and shows a toast message
    - section has a button for inviting a user to a household
      - shows bottom sheet and asks for email address
      - can show error if invite fails (user is already a member of a household or already has an invite for a household that hasn't been accepted/denied yet)
      - Bottom sheet should have segmented controller at top with "Invite by Email" and "Invite by Code" options
        - Invite by Email: input field for email address, button to send invite
        - Invite by Code: input field for name and a button to generate code
          - Tapping button generates a code (UUID), copies to clipboard, shows toast message, and also dismisses modal
    - section has button for leaving household
      - tapping shows confirmation bottom sheet with a dropdown to select new owner
      - tapping leave button on this bottom sheet should show a dialog with Cancel/Leave Household buttons to confirm
  - If user has been invited to a household then we show the invite instead of anything else with accept / decline options

#### Notes:
- Creator becomes owner, first member 
- When a user become a member of a household (either by creating one or accepting an invite), add householdId to all existing personal data
- Use Amazon SES for sending email invites
- The "More" menu is located here: lib/src/widgets/menu/menu.dart
- GoRouter routes are defined in lib/src/mobile/adaptive_app.dart. can look at the existing labs route as a reference for creating a new route for the household sharing page
- The recipe app server directory has been added as a working directory to claude code. can make API changes here
- Can reference the lib/src/services/ingredient_canonicalization_service.dart for how to make backend API calls
- Since creating and modifying of invites in supabase/postgres will only be done via API calls, we can:
  - create an RLS policy in ddls/policies_powersync.sql that permits read-only
  - create the ddl for the new table in ddls/postgres_powersync.sql
  - update the sync rules for powerysnc in ddls/sync-rules.yaml. note that you may have to define the bucket to use the logged in user's email in the display name col in invites. should help this work in cases where a household owner invites a non-existing user via email, meaning we wont have a userId in the invites table. if powersync doesn't work like this, we might need a userId column in invites and a trigger in supabase/pg to set the userId when someone registers with an email that matches the email on an invite
- when building the backend please follow good layering and security practices, thinking carefully about how the app auths with the backend and how the backend auths with supabase.
