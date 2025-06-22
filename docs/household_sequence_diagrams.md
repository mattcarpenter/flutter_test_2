# Household Management Sequence Diagrams

This document contains Mermaid sequence diagrams for the key household management workflows.

## 1. Create Household Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Household UI
    participant P as HouseholdProvider
    participant R as HouseholdRepository
    participant DB as Local Database
    participant PS as PowerSync

    U->>UI: Tap "Create Household"
    UI->>UI: Show CreateHouseholdModal
    U->>UI: Enter household name
    U->>UI: Tap "Create"
    
    UI->>P: createHousehold(name)
    P->>P: Set loading state
    
    P->>R: addHousehold(companion)
    R->>DB: Insert household record
    DB-->>R: Household created
    
    P->>R: addMember(owner companion)
    R->>DB: Insert household member (owner)
    DB-->>R: Member added
    
    DB->>PS: Sync household & member data
    PS-->>DB: Sync confirmation
    
    R-->>P: Operations completed
    P->>P: Clear loading state
    P-->>UI: Success state update
    UI-->>U: Navigate to household management view
```

## 2. Email Invitation Flow

```mermaid
sequenceDiagram
    participant O as Owner
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant Email as Email Service
    participant DB as Supabase DB
    participant I as Invitee
    participant App as Recipe App

    O->>UI: Tap "Invite Member"
    UI->>UI: Show CreateInviteModal
    O->>UI: Select "Invite by Email"
    O->>UI: Enter email address
    O->>UI: Tap "Send Invite"
    
    UI->>P: createEmailInvite(email)
    P->>S: createEmailInvite(householdId, email)
    
    S->>API: POST /invites
    Note over API: Validate household ownership
    API->>DB: Insert invite record
    API->>Email: Send invitation email
    Email-->>I: Invitation email received
    API-->>S: Invite created response
    S-->>P: Success
    P-->>UI: Update invite list
    
    I->>App: Click email link
    App->>UI: Show invite details
    I->>UI: Tap "Accept"
    
    UI->>P: acceptInvite(inviteCode)
    P->>S: acceptInvite(inviteCode)
    S->>API: POST /invites/{code}/accept
    
    API->>DB: Update invite status
    API->>DB: Add household member
    API-->>S: Success response
    
    S-->>P: Membership created
    P-->>UI: Update state
    
    Note over PS: PowerSync syncs household data
    PS->>App: Household data synced
    UI-->>I: Welcome to household!
```

## 3. Code Invitation Flow

```mermaid
sequenceDiagram
    participant O as Owner
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant DB as Supabase DB
    participant I as Invitee
    participant App as Recipe App

    O->>UI: Tap "Invite Member"
    UI->>UI: Show CreateInviteModal
    O->>UI: Select "Invite by Code"
    O->>UI: Enter display name
    O->>UI: Tap "Generate Code"
    
    UI->>P: createCodeInvite(displayName)
    P->>S: createCodeInvite(householdId, displayName)
    
    S->>API: POST /invites
    API->>DB: Insert invite record
    API-->>S: Invite + URL response
    S-->>P: Invite URL
    P-->>UI: Copy URL to clipboard
    UI-->>O: Show "Code copied!" toast
    
    O->>I: Share URL/code via text/chat
    I->>App: Open shared URL
    App->>UI: Show invite details page
    UI->>UI: Display household info & inviter
    I->>UI: Tap "Accept"
    
    UI->>P: acceptInvite(inviteCode)
    P->>S: acceptInvite(inviteCode)
    S->>API: POST /invites/{code}/accept
    
    API->>DB: Update invite status
    API->>DB: Add household member
    API-->>S: Success response
    
    S-->>P: Membership created
    P-->>UI: Update state
    
    Note over PS: PowerSync syncs household data
    PS->>App: Household data synced
    UI-->>I: Welcome to household!
```

## 4. PowerSync Data Synchronization

```mermaid
sequenceDiagram
    participant U as New Member
    participant App as Flutter App
    participant PS as PowerSync
    participant DB as Supabase DB
    
    Note over U: User joins household
    U->>App: Accept invitation
    App->>DB: Create household membership
    
    Note over PS: PowerSync detects membership change
    PS->>DB: Query household data based on sync rules
    DB-->>PS: Household members' data
    
    Note over PS: Sync rules automatically include:
    Note over PS: - All recipes with householdId
    Note over PS: - All shopping lists with householdId
    Note over PS: - All pantry items with householdId
    Note over PS: - All meal plans with householdId
    
    PS->>App: Sync household data to device
    App->>App: Update local database
    App-->>U: Household data now available
    
    Note over U: User creates new recipe
    U->>App: Create recipe with householdId
    App->>PS: Sync new recipe
    PS->>DB: Store recipe with householdId
    
    Note over PS: All household members receive update
    PS->>App: Sync to all member devices
```

## 5. Leave Household Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant DB as Supabase DB

    U->>UI: Tap "Leave Household"
    
    alt User is Owner
        UI->>UI: Show owner transfer modal
        UI->>UI: Display member dropdown
        U->>UI: Select new owner
        U->>UI: Tap "Leave & Transfer"
        UI->>P: leaveHousehold(newOwnerId)
    else User is Member
        UI->>UI: Show confirmation dialog
        U->>UI: Tap "Leave Household"
        UI->>P: leaveHousehold()
    end
    
    P->>S: leaveHousehold(householdId, newOwnerId?)
    S->>API: POST /leave
    
    Note over API: Validate permissions
    
    opt If ownership transfer needed
        API->>DB: UPDATE member role = 'owner'
        API->>DB: UPDATE leaving user role = 'member'
    end
    
    API->>DB: UPDATE member isActive = false
    API->>DB: Set member deletedAt timestamp
    
    API-->>S: Success
    S-->>P: Left household
    P-->>UI: Update state
    
    Note over PS: PowerSync removes household data access
    PS->>App: Sync removes household data
    Note over U: User loses access to household data
    Note over U: Personal data remains unchanged
    UI-->>U: "You've left the household"
```

## 6. Remove Member Flow

```mermaid
sequenceDiagram
    participant O as Owner/Admin
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant DB as Supabase DB
    participant PS as PowerSync
    participant M as Removed Member

    O->>UI: Tap "..." on member tile
    UI->>UI: Show context menu
    O->>UI: Tap "Remove Member"
    UI->>UI: Show confirmation dialog
    O->>UI: Tap "Remove"
    
    UI->>P: removeMember(memberId)
    P->>S: removeMember(memberId)
    S->>API: DELETE /members/{memberId}
    
    Note over API: Validate owner/admin permissions
    API->>DB: UPDATE member isActive = false
    API->>DB: Set member deletedAt timestamp
    
    API-->>S: Success
    S-->>P: Member removed
    P-->>UI: Update member list
    
    PS->>M: Sync removes household access
    Note over M: User loses access to household data
    Note over M: User's personal data remains unchanged
    Note over M: Any data created with householdId stays with household
```

## 7. Revoke Invitation Flow

```mermaid
sequenceDiagram
    participant O as Owner/Admin
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant DB as Supabase DB
    participant I as Invitee

    O->>UI: View pending invites
    O->>UI: Tap "..." on invite
    UI->>UI: Show context menu
    O->>UI: Tap "Revoke Invite"
    UI->>UI: Show confirmation dialog
    O->>UI: Tap "Revoke"
    
    UI->>P: revokeInvite(inviteId)
    P->>S: revokeInvite(inviteId)
    S->>API: DELETE /invites/{inviteId}
    
    API->>DB: UPDATE invite status = 'revoked'
    API->>DB: Set invite deletedAt timestamp
    API-->>S: Success
    S-->>P: Invite revoked
    P-->>UI: Remove from invite list
    
    Note over I: If invitee tries to use code
    I->>API: POST /invites/{code}/accept
    API-->>I: 404 Invite not found/expired
```

## 8. Resend Email Invitation

```mermaid
sequenceDiagram
    participant O as Owner/Admin
    participant UI as Household UI
    participant P as HouseholdProvider
    participant S as HouseholdService
    participant API as Backend API
    participant DB as Supabase DB
    participant Email as Email Service
    participant I as Invitee

    O->>UI: View pending invites
    O->>UI: Tap "..." on email invite
    UI->>UI: Show context menu
    O->>UI: Tap "Resend Invite"
    
    UI->>P: resendInvite(inviteId)
    P->>S: resendInvite(inviteId)
    S->>API: POST /invites/{inviteId}/resend
    
    Note over API: Check rate limiting (15 min)
    alt Rate limit OK
        API->>DB: UPDATE lastSentAt timestamp
        API->>Email: Send invitation email
        Email-->>I: New invitation email
        API-->>S: Success
        S-->>P: Email sent
        P-->>UI: Show "Email sent" toast
    else Rate limited
        API-->>S: 429 Too Many Requests
        S-->>P: Rate limit error
        P-->>UI: Show "Please wait 15 minutes" error
    end
```

## 9. Error Handling Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as UI Component
    participant P as Provider
    participant S as Service
    participant API as Backend API

    U->>UI: Perform action (e.g., accept invite)
    UI->>P: Call provider method
    P->>S: Call service method
    S->>API: HTTP request
    
    alt Success Response
        API-->>S: 200 OK + data
        S-->>P: Success result
        P->>P: Update state
        P-->>UI: Success state
        UI-->>U: Show success feedback
    else Client Error (4xx)
        API-->>S: 400/401/403/404 + error
        S->>S: Parse error response
        S-->>P: Throw HouseholdApiException
        P->>P: Update error state
        P-->>UI: Error state
        UI-->>U: Show error message
    else Server Error (5xx)
        API-->>S: 500 + error
        S-->>P: Throw HouseholdApiException
        P->>P: Update error state
        P-->>UI: Error state
        UI-->>U: Show "Server error" message
    else Network Error
        S-->>P: Throw NetworkException
        P->>P: Update error state
        P-->>UI: Error state
        UI-->>U: Show "Check connection" message
    end
```

## 10. Progressive Disclosure UX Flow

```mermaid
sequenceDiagram
    participant U as User
    participant App as App
    participant UI as Household Page
    participant P as Provider

    U->>App: Navigate to Household Sharing
    App->>UI: Load HouseholdSharingPage
    UI->>P: Watch household state
    
    alt No Household + No Invites
        P-->>UI: Empty state
        UI-->>U: Show Create/Join buttons
        Note over U: Progressive disclosure level 1
    else Has Pending Invites
        P-->>UI: Pending invites state
        UI-->>U: Show invite cards with Accept/Decline
        Note over U: Progressive disclosure level 2
    else Has Household
        P-->>UI: Household management state
        
        alt User is Owner/Admin
            UI-->>U: Show full management interface
            Note over U: Members + Invites + Actions
            Note over U: Progressive disclosure level 3a
        else User is Member
            UI-->>U: Show limited interface
            Note over U: Members + Leave option only
            Note over U: Progressive disclosure level 3b
        end
    end
    
    Note over UI: Each level reveals more functionality
    Note over UI: Prevents overwhelming new users
```

## Key Design Principles

### 1. Progressive Disclosure
- Start with simple Create/Join options
- Gradually reveal more complex features
- Role-based feature visibility

### 2. Async Operations
- All API calls are asynchronous
- Progress indicators for long operations
- Graceful error handling

### 3. Data Consistency
- PowerSync handles offline/online sync
- Optimistic UI updates where safe
- Rollback capability for failures

### 4. Security First
- All operations validate permissions
- Rate limiting prevents abuse
- Audit trails for sensitive actions

### 5. User Experience
- Clear feedback for all actions
- Confirmation dialogs for destructive operations
- Helpful error messages with recovery actions

These sequence diagrams provide a comprehensive view of how the household management system works across all the major user flows, showing the interaction between frontend components, backend services, and data persistence layers.