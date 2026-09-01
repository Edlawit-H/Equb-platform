# Equb API â€” Postman Testing Guide

Base URL: `http://localhost:5000`
API Prefix: `http://localhost:5000/api/v1`

---

## Postman Environment Variables

Create a Postman Environment and add these variables before starting:

| Variable | Value | How to get it |
|---|---|---|
| `baseUrl` | `http://localhost:5000/api/v1` | Manual |
| `token_admin` | *(empty)* | From verify-otp or login response |
| `token_b` | *(empty)* | From verify-otp or login response |
| `token_c` | *(empty)* | From verify-otp or login response |
| `group_id` | *(empty)* | From create group response |
| `invite_code` | *(empty)* | From create group response |
| `member_id_b` | *(empty)* | From get members response |
| `member_id_c` | *(empty)* | From get members response |
| `contribution_id` | *(empty)* | From get contributions response |
| `payout_id` | *(empty)* | From get payouts response |
| `notification_id` | *(empty)* | From get notifications response |
| `transaction_id` | *(empty)* | From get transactions response |

---

## Phase 1 â€” Health Check

### 1.1 Server Health
**Owner: Both**
```
Method: GET
URL:    http://localhost:5000/health
Auth:   None
```
Expected 200:
```json
{
  "status": "ok",
  "db": "ok",
  "uptime": 14.52,
  "timestamp": "2026-08-12T10:00:00.000Z"
}
```

---

## Phase 2 â€” Authentication
**Owner: Etsub** (core auth â€” register, OTP, login, forgot/reset password)

### 2.1 Register Admin User
```
Method: POST
URL:    {{baseUrl}}/auth/register
Auth:   None
Body (JSON):
{
  "full_name": "Edlawit Admin",
  "phone_number": "+251911111111",
  "password": "Password123!"
}
```
Expected 200:
```json
{
  "message": "OTP sent",
  "data": { "message": "OTP generated" }
}
```
> In dev mode the server prints the OTP to the terminal AND the app shows a pop-up dialog with the code. Copy it from either place.

### 2.2 Register Member B
```
Method: POST
URL:    {{baseUrl}}/auth/register
Auth:   None
Body (JSON):
{
  "full_name": "Etsub Member",
  "phone_number": "+251922222222",
  "password": "Password123!"
}
```
Expected 200:
```json
{
  "message": "OTP sent",
  "data": { "message": "OTP generated" }
}
```

### 2.3 Register Member C
```
Method: POST
URL:    {{baseUrl}}/auth/register
Auth:   None
Body (JSON):
{
  "full_name": "Hana Member",
  "phone_number": "+251933333333",
  "password": "Password123!"
}
```
Expected 200:
```json
{
  "message": "OTP sent",
  "data": { "message": "OTP generated" }
}
```

### 2.4 Verify OTP â€” Admin (creates account)
```
Method: POST
URL:    {{baseUrl}}/auth/verify-otp
```
> Common mistake: do NOT use `/auth/register/verify-otp` â€” the correct path is `/auth/verify-otp`
Body (JSON):
{
  "phone_number": "+251911111111",
  "otp_code": "123456",
  "password": "Password123!",
  "full_name": "Edlawit Admin"
}
```
Expected 201:
```json
{
  "message": "Account created successfully",
  "data": {
    "user": {
      "user_id": "uuid-here",
      "full_name": "Edlawit Admin",
      "phone_number": "+251911111111",
      "role": "member",
      "wallet_balance": "0.00"
    },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```
> Save `data.accessToken` â†’ `token_admin`

### 2.5 Verify OTP â€” Member B
```
Method: POST
URL:    {{baseUrl}}/auth/verify-otp
Auth:   None
Body (JSON):
{
  "phone_number": "+251922222222",
  "otp_code": "123456",
  "password": "Password123!",
  "full_name": "Etsub Member"
}
```
Expected 201 â€” same structure as 2.4.
> Save `data.accessToken` â†’ `token_b`

### 2.6 Verify OTP â€” Member C
```
Method: POST
URL:    {{baseUrl}}/auth/verify-otp
Auth:   None
Body (JSON):
{
  "phone_number": "+251933333333",
  "otp_code": "123456",
  "password": "Password123!",
  "full_name": "Hana Member"
}
```
Expected 201 â€” same structure as 2.4.
> Save `data.accessToken` â†’ `token_c`

### 2.7 Login
```
Method: POST
URL:    {{baseUrl}}/auth/login
Auth:   None
Body (JSON):
{
  "phone_number": "+251911111111",
  "password": "Password123!"
}
```
Expected 200:
```json
{
  "message": "Login successful",
  "data": {
    "user": {
      "user_id": "uuid-here",
      "full_name": "Edlawit Admin",
      "phone_number": "+251911111111",
      "role": "member"
    },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

### 2.8 Login â€” Wrong Password (Edge Case)
```
Method: POST
URL:    {{baseUrl}}/auth/login
Auth:   None
Body (JSON):
{
  "phone_number": "+251911111111",
  "password": "WrongPassword!"
}
```
Expected 500 (error thrown):
```json
{
  "status": "error",
  "message": "Invalid phone number or password"
}
```

### 2.9 Forgot Password
```
Method: POST
URL:    {{baseUrl}}/auth/forgot-password
Auth:   None
Body (JSON):
{
  "phone_number": "+251911111111"
}
```
Expected 200:
```json
{
  "message": "OTP sent"
}
```
> OTP is printed to the terminal. The Reset Password screen (frontend) also shows the OTP in a pop-up dialog when navigating from Forgot Password.

### 2.10 Reset Password
```
Method: POST
URL:    {{baseUrl}}/auth/reset-password
Auth:   None
Body (JSON):
{
  "phone_number": "+251911111111",
  "otp_code": "123456",
  "new_password": "NewPassword123!"
}
```
Expected 200:
```json
{
  "message": "Password updated successfully"
}
```

### 2.11 Get Profile
**Owner: Etsub**
```
Method: GET
URL:    {{baseUrl}}/auth/profile
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "user_id": "uuid-here",
  "full_name": "Edlawit Admin",
  "phone_number": "+251911111111",
  "email": null,
  "profile_image": null,
  "role": "member",
  "wallet_balance": "0.00",
  "created_at": "2026-08-12T10:00:00.000Z"
}
```

### 2.12 Update Profile
**Owner: Etsub**
```
Method: PUT
URL:    {{baseUrl}}/auth/profile
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "full_name": "Edlawit Admin Updated"
}
```
Expected 200 â€” returns updated user object.

---

## Phase 3 â€” User Management
**Owner: Etsub**

### 3.1 Get User by ID
```
Method: GET
URL:    {{baseUrl}}/users/:id
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” public profile: name, avatar, role.

### 3.2 Search Users
```
Method: GET
URL:    {{baseUrl}}/users/search?q=Edlawit
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” array of matching users.

### 3.3 Get User Groups
```
Method: GET
URL:    {{baseUrl}}/users/:id/groups
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” array of groups user belongs to.

### 3.4 Update User (Admin)
```
Method: PUT
URL:    {{baseUrl}}/users/:id
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "full_name": "Updated Name"
}
```
Expected 200 â€” updated user object.

### 3.5 Change Password (2-step OTP flow)
**Step 1 — Request OTP**
```
Method: POST
URL:    {{baseUrl}}/auth/change-password/request-otp
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "current_password": "Password123!",
  "new_password": "NewPassword456!"
}
```
Expected 200:
```json
{
  "message": "OTP sent",
  "data": {
    "masked_phone": "+251911****111"
  }
}
```
> The server sends an OTP with purpose `password_change`. In dev mode the OTP is printed to the terminal and the app shows a pop-up dialog (same orange dialog used for registration OTP). Copy the code from either place.

**Step 2 — Confirm with OTP**
```
Method: POST
URL:    {{baseUrl}}/auth/change-password
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "current_password": "Password123!",
  "new_password": "NewPassword456!",
  "otp_code": "123456"
}
```
Expected 200:
```json
{ "message": "Password changed successfully" }
```

### 3.6 Loans Stub
```
Method: GET
URL:    {{baseUrl}}/users/:id/loans
Auth:   Bearer {{token_admin}}
```
Expected 501:
```json
{
  "status": "error",
  "message": "Not implemented"
}
```

---

## Phase 4 â€” Wallet & Transactions
**Owner: Edlawit**

### 4.1 Get Wallet Balance
```
Method: GET
URL:    {{baseUrl}}/transactions/wallet
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "wallet_balance": "0.00",
  "last_transaction_at": null
}
```

### 4.2 Top Up Wallet â€” Admin
```
Method: POST
URL:    {{baseUrl}}/transactions/top-up
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "amount": 10000
}
```
Expected 200:
```json
{
  "message": "Wallet topped up successfully",
  "new_balance": "10000.00",
  "transaction_id": "uuid-here"
}
```
> Repeat with `token_b` (amount: 5000) and `token_c` (amount: 5000).

### 4.3 Top Up â€” Negative Amount (Edge Case)
```
Method: POST
URL:    {{baseUrl}}/transactions/top-up
Auth:   Bearer {{token_admin}}
Body (JSON):
0
```
Expected 400:
```json
{
  "status": "error",
  "message": "Validation failed",
  "details": { "body": { "amount": ["Number must be greater than 0"] } }
}
```

### 4.4 Get All Transactions
```
Method: GET
URL:    {{baseUrl}}/transactions
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "transactions": [
    {
      "transaction_id": "uuid",
      "type": "top_up",
      "amount": "10000.00",
      "status": "completed",
      "created_at": "2026-08-12T10:00:00.000Z"
    }
  ],
  "total": 1,
  "page": 1
}
```

### 4.5 Get Transactions â€” Filter by Type
```
Method: GET
URL:    {{baseUrl}}/transactions?type=top_up
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” filtered list.

### 4.6 Get Transactions â€” Filter by Date Range
```
Method: GET
URL:    {{baseUrl}}/transactions?from=2026-01-01&to=2026-12-31
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” filtered list within date range.

### 4.7 Get Single Transaction
```
Method: GET
URL:    {{baseUrl}}/transactions/{{transaction_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” single transaction detail.

### 4.8 Get Transaction Stats
```
Method: GET
URL:    {{baseUrl}}/transactions/stats
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "total_credited": "10000.00",
  "total_debited": "0.00",
  "net_balance": "10000.00"
}
```

### 4.9 Get Group Transactions
```
Method: GET
URL:    {{baseUrl}}/transactions/group/{{group_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” transactions linked to that group.

### 4.10 Export Transactions (CSV)
```
Method: GET
URL:    {{baseUrl}}/transactions/export
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” CSV download or URL.

### 4.11 Refund Stub
```
Method: POST
URL:    {{baseUrl}}/transactions/refund
Auth:   Bearer {{token_admin}}
```
Expected 501:
```json
{ "status": "error", "message": "Not implemented" }
```

---

## Phase 5 â€” Group Management
**Owner: Etsub**

### 5.1 Create Group
```
Method: POST
URL:    {{baseUrl}}/groups
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_name": "Fast Track Equb",
  "description": "Test group for 3 members",
  "contribution_amount": 1000,
  "cycle_duration": 7,
  "max_members": 3,
  "selection_mode": "positional"
}
```
> `selection_mode` options: `"positional"` (default) or `"random"`
> Positional: winner of cycle N = member with position_in_cycle = N (determined by join order, no admin picking)
> Random: winner randomly selected from members who haven't received a payout yet
> `"contribution_deadline_days": 2` can be added for 2-day deadline (default is 1 day)

Expected 201:
```json
{
  "success": true,
  "message": "Group created successfully",
  "data": {
    "group_id": "uuid-here",
    "group_name": "Fast Track Equb",
    "invitation_code": "A1B2C3D4",
    "status": "pending",
    "contribution_amount": "1000.00",
    "cycle_duration": 7,
    "max_members": 3,
    "current_cycle": 1,
    "selection_mode": "positional",
    "contribution_deadline_days": 1
  }
}
```
> Save `data.group_id` â†’ `group_id` and `data.invitation_code` â†’ `invite_code`

### 5.2 Create Group â€” Invalid Cycle Duration (Edge Case)
```
Method: POST
URL:    {{baseUrl}}/groups
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_name": "Bad Group",
  "contribution_amount": 500,
  "cycle_duration": 15,
  "max_members": 5
}
```
Expected 400 â€” validation error (cycle_duration must be 7, 14, or 30).

### 5.3 Get My Groups
```
Method: GET
URL:    {{baseUrl}}/groups
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” array of groups admin belongs to.

### 5.4 Get Group By ID
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” full group detail including invitation_code (admin only).

### 5.5 Update Group Name
```
Method: PUT
URL:    {{baseUrl}}/groups/{{group_id}}
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_name": "Fast Track Equb v2"
}
```
Expected 200 â€” updated group object.

### 5.6 Get Group Members
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/members
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "members": [
    {
      "member_id": "uuid",
      "full_name": "Edlawit Admin",
      "position_in_cycle": 1,
      "role": "admin",
      "status": "active"
    }
  ]
}
```

### 5.7 Member B Joins Group
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_b}}
Body:   (empty â€” no invitation_code needed, join is by group_id in URL)
```
Expected 200:
```json
{
  "message": "Joined group successfully",
  "data": {
    "member_id": "uuid",
    "group_id": "uuid",
    "role": "member",
    "position_in_cycle": 2
  }
}
```
> Save `data.member_id` â†’ `member_id_b`

### 5.8 Member C Joins Group
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_c}}
Body:   (empty)
```
Expected 200:
```json
{
  "message": "Joined group successfully",
  "data": {
    "member_id": "uuid",
    "group_id": "uuid",
    "role": "member",
    "position_in_cycle": 3
  }
}
```
> Save `data.member_id` â†’ `member_id_c`

### 5.9 Join Already Full Group (Edge Case)
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "invitation_code": "{{invite_code}}"
}
```
Expected 400 â€” group is full or already a member.

### 5.10 Start Group
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/start
Auth:   Bearer {{token_admin}}
Body:   (empty)
```
Expected 200:
```json
{
  "success": true,
  "message": "Group started successfully",
  "data": {
    "group_id": "uuid",
    "status": "active",
    "start_date": "2026-08-14",
    "end_date": "2026-09-04",
    "cycle_1_due_date": "2026-08-15",
    "total_cycles": 3,
    "members_count": 3
  }
}
```
> total_cycles = actual members at start time, NOT max_members.
> If max_members was 3 but only 2 joined, total_cycles = 2 and only 2 payout cycles run.
> contribution due_date = start_date + 1 day (or + 2 if contribution_deadline_days = 2)
> cycle_end_date = start_date + 7 days â€” stored on equb_groups
> Cycle 1 contributions generated for all members present at start.
> Next cycle starts only when: cycle_end_date passed AND payout for current cycle completed.

### 5.11 Leave Active Group (Edge Case â€” must fail)
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/leave
Auth:   Bearer {{token_b}}
```
Expected 400:
```json
{
  "status": "error",
  "message": "Cannot leave an active group"
}
```

### 5.12 Join Started Group (Edge Case â€” must fail)
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_b}}
Body (JSON):
{
  "invitation_code": "{{invite_code}}"
}
```
Expected 400:
```json
{
  "status": "error",
  "message": "Cannot join a group that has already started"
}
```

### 5.13 Regenerate Invitation Code
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/invite
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "message": "Invitation code regenerated",
  "invitation_code": "XYZ99999"
}
```

### 5.14 Get Group Dashboard
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/dashboard
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "group_name": "Fast Track Equb v2",
  "current_cycle": 1,
  "total_members": 3,
  "total_collected_this_cycle": "0.00",
  "next_payout_date": "2026-08-19",
  "unpaid_members": ["Etsub Member", "Hana Member"]
}
```

### 5.15 Get Group Activity Log
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/activity
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” chronological list of events.

### 5.16 Get Group Contributions
**Owner: Edlawit (endpoint) / Etsub (GroupDetailScreen Contributions tab)**
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/contributions
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "contributions": [
    {
      "contribution_id": "uuid",
      "member_name": "Edlawit Admin",
      "cycle_number": 1,
      "amount": "1000.00",
      "due_date": "2026-08-19",
      "paid_date": null,
      "status": "pending"
    }
  ]
}
```

### 5.17 Get Group Payouts
**Owner: Edlawit (endpoint) / Etsub (GroupDetailScreen Payouts tab)**
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/payouts
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” empty array until first payout fires.

### 5.18 Promote Member to Co-Admin
```
Method: PATCH
URL:    {{baseUrl}}/groups/{{group_id}}/members/{{member_id_b}}/role
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "role": "co_admin"
}
```
Expected 200 â€” updated member with role `co_admin`.

### 5.19 Delete Group (Edge Case â€” must fail for active group)
```
Method: DELETE
URL:    {{baseUrl}}/groups/{{group_id}}
Auth:   Bearer {{token_admin}}
```
Expected 400 â€” cannot delete an active group.

---

## Phase 6 â€” Contributions
**Owner: Edlawit**

### 6.1 Get My Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” list of admin's contributions with status `pending`.

### 6.2 Get Pending Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions/pending
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” unpaid contributions across all groups.

### 6.3 Get Overdue Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions/overdue
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” empty list if none are overdue yet.

### 6.4 Get Contribution Stats
```
Method: GET
URL:    {{baseUrl}}/contributions/stats
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "total_paid": 0,
  "total_overdue": 0,
  "on_time_rate": 0
}
```

### 6.5 Admin Pays Contribution â€” Cycle 1 (1 of 3)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 1
}
```
Expected 200:
```json
{
  "status": "success",
  "message": "Contribution paid successfully",
  "data": {
    "contribution_id": "uuid",
    "amount": 1000,
    "transaction_id": "uuid"
  }
}
```
> Admin wallet debited 1000. 1/3 paid. No payout yet.

### 6.6 Member B Pays Contribution â€” Cycle 1 (2 of 3)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_b}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 1
}
```
Expected 200 â€” wallet debited 1000. 2/3 paid. No payout yet.

### 6.7 Member C Pays â€” Cycle 1 (3 of 3 â€” AUTO PAYOUT FIRES)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_c}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 1
}
```
Expected 200:
```json
{
  "status": "success",
  "message": "Contribution paid successfully",
  "data": {
    "contribution_id": "uuid",
    "amount": 1000,
    "transaction_id": "uuid"
  }
}
```
> All 3 paid â†’ payout fires automatically:
> - Winner = position_in_cycle 1 = Admin (positional mode)
> - payout_amount = 1000 Ã— 3 = 3000 ETB
> - Admin wallet credited 3000 ETB
> - Payout record created (status: completed)
> - Cycle stays at 1 â€” next cycle does NOT start yet
> - Next cycle starts only after cycle_end_date (start_date + 7 days) has passed

### 6.8 Duplicate Contribution (Edge Case)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 1
}
```
Expected 400:
```json
{
  "status": "error",
  "message": "Already paid for this cycle"
}
```

### 6.9 Pay Wrong Cycle (Edge Case â€” must fail)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_b}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 2
}
```
Expected 400:
```json
{
  "status": "error",
  "message": "Cannot pay for cycle 2. The current active cycle is 1"
}
```
> Cycle 2 contributions do not exist yet â€” they are only created when cycle 1 ends.

### 6.10 Get Single Contribution
```
Method: GET
URL:    {{baseUrl}}/contributions/{{contribution_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” single contribution detail.

### 6.11 Bulk Mark as Paid (Admin Only)
```
Method: POST
URL:    {{baseUrl}}/contributions/bulk
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "group_id": "{{group_id}}",
  "cycle_number": 2,
  "member_ids": ["{{member_id_b}}", "{{member_id_c}}"]
}
```
Expected 200:
```json
{
  "message": "Bulk contributions recorded",
  "count": 2
}
```

### 6.12 Manual Contribution Entry (Admin Only)
```
Method: POST
URL:    {{baseUrl}}/contributions/manual
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "member_id": "{{member_id_b}}",
  "group_id": "{{group_id}}",
  "cycle_number": 2
}
```
Expected 200 â€” contribution recorded for that member.

---

## Phase 7 â€” Payouts
**Owner: Edlawit**

### 7.1 Get My Payouts
```
Method: GET
URL:    {{baseUrl}}/payouts
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "payouts": [
    {
      "payout_id": "uuid",
      "payout_amount": "3000.00",
      "cycle_number": 1,
      "payout_date": "2026-08-12T10:05:00.000Z",
      "status": "completed"
    }
  ]
}
```
> Save `payouts[0].payout_id` â†’ `payout_id`

### 7.2 Get Payout History
```
Method: GET
URL:    {{baseUrl}}/payouts/history
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” same as above with group context.

### 7.3 Get Payout Schedule
```
Method: GET
URL:    {{baseUrl}}/payouts/schedule
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” projected payout dates for active groups.

### 7.4 Get Single Payout
```
Method: GET
URL:    {{baseUrl}}/payouts/{{payout_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” single payout detail.

### 7.5 Approve Payout Manually (Admin)
```
Method: POST
URL:    {{baseUrl}}/payouts/{{payout_id}}/approve
Auth:   Bearer {{token_admin}}
```
Expected 200 or 400 if already completed.

### 7.6 Reject Payout (Admin)
```
Method: POST
URL:    {{baseUrl}}/payouts/{{payout_id}}/reject
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” payout status set to `rejected`.

---

## Phase 8 â€” Reports & Dashboard
**Owner: Edlawit**

### 8.1 Get Home Dashboard
```
Method: GET
URL:    {{baseUrl}}/reports/dashboard
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "wallet_balance": "12000.00",
  "active_groups": 1,
  "next_due_contribution": {
    "group_name": "Fast Track Equb v2",
    "amount": "1000.00",
    "due_date": "2026-08-19"
  },
  "recent_transactions": [...]
}
```

### 8.2 Get User Summary
```
Method: GET
URL:    {{baseUrl}}/reports/user-summary
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "total_contributed": "1000.00",
  "total_received": "3000.00",
  "wallet_balance": "12000.00",
  "active_group_count": 1,
  "completed_group_count": 0
}
```

### 8.3 Get User Summary â€” Date Filter
```
Method: GET
URL:    {{baseUrl}}/reports/user-summary?from=2026-01-01&to=2026-12-31
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” same structure, filtered by date.

### 8.4 Get Group Summary
```
Method: GET
URL:    {{baseUrl}}/reports/group-summary?group_id={{group_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "total_collected": "3000.00",
  "total_paid_out": "3000.00",
  "remaining_cycles": 2,
  "cycle_completion_percentage": 100,
  "member_payment_statuses": [...]
}
```

### 8.5 Get Contribution Stats Report
```
Method: GET
URL:    {{baseUrl}}/reports/contributions
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” contribution analytics.

### 8.6 Get Payout Stats Report
```
Method: GET
URL:    {{baseUrl}}/reports/payouts
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” payout analytics.

### 8.7 Get Financial Overview
```
Method: GET
URL:    {{baseUrl}}/reports/financial
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” combined wallet + contribution + payout overview.

### 8.8 Get Analytics
```
Method: GET
URL:    {{baseUrl}}/reports/analytics
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” Chart.js-compatible time series data.

### 8.9 Export PDF Report
```
Method: GET
URL:    {{baseUrl}}/reports/export/pdf
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "download_url": "http://localhost:5000/exports/report-uuid.pdf",
  "expires_at": "2026-08-13T10:00:00.000Z"
}
```

### 8.10 Export Excel Report
```
Method: GET
URL:    {{baseUrl}}/reports/export/excel
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” same structure with `.xlsx` URL.

---

## Phase 9 â€” Notifications
**Owner: Etsub**

> These endpoints return empty/stub responses until Etsub wires the notification routes.

### 9.1 Get All Notifications
```
Method: GET
URL:    {{baseUrl}}/notifications
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "notifications": [],
  "total": 0,
  "unread_count": 0
}
```

### 9.2 Get Unread Count
```
Method: GET
URL:    {{baseUrl}}/notifications/unread
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{ "unread_count": 0 }
```

### 9.3 Get Single Notification
```
Method: GET
URL:    {{baseUrl}}/notifications/{{notification_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” single notification detail.

### 9.4 Mark One as Read
```
Method: PATCH
URL:    {{baseUrl}}/notifications/{{notification_id}}/read
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{ "message": "Notification marked as read" }
```

### 9.5 Mark All as Read
```
Method: PATCH
URL:    {{baseUrl}}/notifications/read-all
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{ "message": "All notifications marked as read" }
```

### 9.6 Delete Notification
```
Method: DELETE
URL:    {{baseUrl}}/notifications/{{notification_id}}
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{ "message": "Notification deleted" }
```

### 9.7 Get Notification Settings
```
Method: GET
URL:    {{baseUrl}}/notifications/settings
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "payment_reminders": true,
  "payout_alerts": true,
  "group_activity": true
}
```

### 9.8 Update Notification Settings
```
Method: PATCH
URL:    {{baseUrl}}/notifications/settings
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "payment_reminders": true,
  "payout_alerts": true,
  "group_activity": false
}
```
Expected 200 â€” updated preferences.

---

## Phase 10 â€” Admin Panel
**Owner: Etsub**

> These endpoints require the user's `role` to be `system_admin` in the DB. Update manually for testing:
> `UPDATE users SET role = 'system_admin' WHERE phone_number = '+251911111111';`

### 10.1 Platform Dashboard
```
Method: GET
URL:    {{baseUrl}}/admin/dashboard
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "total_users": 3,
  "total_groups": 1,
  "total_transaction_volume": "13000.00"
}
```

### 10.2 List All Users
```
Method: GET
URL:    {{baseUrl}}/admin/users
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” paginated list of all users.

### 10.3 List All Users â€” Filter by Status
```
Method: GET
URL:    {{baseUrl}}/admin/users?status=active
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” filtered user list.

### 10.4 List All Groups
```
Method: GET
URL:    {{baseUrl}}/admin/groups
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” paginated list of all groups.

### 10.5 Platform Report
```
Method: GET
URL:    {{baseUrl}}/admin/reports
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” platform-level financial overview.

### 10.6 Suspend User
```
Method: PATCH
URL:    {{baseUrl}}/admin/users/{{member_id_b}}/status
Auth:   Bearer {{token_admin}}
Body (JSON):
{
  "status": "suspended"
}
```
Expected 200:
```json
{ "message": "User status updated", "status": "suspended" }
```

### 10.7 Soft Delete User
```
Method: DELETE
URL:    {{baseUrl}}/admin/users/{{member_id_c}}
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{ "message": "User deleted" }
```

### 10.8 Get Audit Logs
```
Method: GET
URL:    {{baseUrl}}/admin/logs
Auth:   Bearer {{token_admin}}
```
Expected 200 â€” paginated audit_logs list.

### 10.9 System Health (Auth-gated)
```
Method: GET
URL:    {{baseUrl}}/admin/system-health
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "status": "ok",
  "uptime": 120.5
}
```

### 10.10 Backup Stub
```
Method: POST
URL:    {{baseUrl}}/admin/backup
Auth:   Bearer {{token_admin}}
```
Expected 501:
```json
{ "status": "error", "message": "Not implemented" }
```

### 10.11 Settings Stub
```
Method: POST
URL:    {{baseUrl}}/admin/settings
Auth:   Bearer {{token_admin}}
```
Expected 501:
```json
{ "status": "error", "message": "Not implemented" }
```

---

## Complete Endpoint Reference

| # | Method | Endpoint | Auth | Owner | Status |
|---|---|---|---|---|---|
| 1 | GET | /health | None | Both | Live |
| 2 | POST | /auth/register | None | Etsub | Live |
| 3 | POST | /auth/verify-otp | None | Etsub | Live |
| 4 | POST | /auth/login | None | Etsub | Live |
| 5 | POST | /auth/forgot-password | None | Etsub | Live |
| 6 | POST | /auth/reset-password | None | Etsub | Live |
| 7 | GET | /auth/profile | Bearer | Etsub | Live |
| 8 | PUT | /auth/profile | Bearer | Etsub | Live |
| 9 | PUT | /auth/change-password | Bearer | Etsub | Stub |
| 10 | DELETE | /auth/account | Bearer | Etsub | Stub |
| 11 | POST | /auth/biometric | Bearer | Etsub | Stub |
| 12 | POST | /auth/check-phone | None | Etsub | Stub |
| 13 | POST | /auth/register-device | Bearer | Etsub | Stub |
| 14 | DELETE | /auth/register-device | Bearer | Etsub | Stub |
| 15 | GET | /users/:id | Bearer | Etsub | Stub |
| 16 | PUT | /users/:id | Bearer | Etsub | Stub |
| 17 | DELETE | /users/:id | Bearer | Etsub | Stub |
| 18 | PATCH | /users/:id/status | Bearer | Etsub | Stub |
| 19 | GET | /users/search | Bearer | Etsub | Stub |
| 20 | GET | /users/:id/groups | Bearer | Etsub | Stub |
| 21 | GET | /users/:id/notifications | Bearer | Etsub | Stub |
| 22 | GET | /users/:id/loans | Bearer | Etsub | Stub (501) |
| 23 | GET | /users/me/sessions | Bearer | Etsub | Stub |
| 24 | DELETE | /users/me/sessions/:id | Bearer | Etsub | Stub |
| 25 | DELETE | /users/me/sessions | Bearer | Etsub | Stub |
| 26 | GET | /transactions/wallet | Bearer | Edlawit | Live |
| 27 | POST | /transactions/top-up | Bearer | Edlawit | Live |
| 28 | GET | /transactions | Bearer | Edlawit | Live |
| 29 | GET | /transactions/:id | Bearer | Edlawit | Live |
| 30 | GET | /transactions/stats | Bearer | Edlawit | Live |
| 31 | GET | /transactions/history | Bearer | Edlawit | Live |
| 32 | GET | /transactions/filter | Bearer | Edlawit | Live |
| 33 | GET | /transactions/group/:groupId | Bearer | Edlawit | Live |
| 34 | GET | /transactions/export | Bearer | Edlawit | Stub |
| 35 | POST | /transactions/refund | Bearer | Edlawit | Stub (501) |
| 36 | POST | /groups | Bearer | Etsub | Live |
| 37 | GET | /groups | Bearer | Etsub | Live |
| 38 | GET | /groups/:id | Bearer | Etsub | Live |
| 39 | PUT | /groups/:id | Bearer | Etsub | Live |
| 40 | DELETE | /groups/:id | Bearer | Etsub | Live |
| 41 | POST | /groups/:id/join | Bearer | Etsub | Live |
| 42 | POST | /groups/:id/leave | Bearer | Etsub | Live |
| 43 | POST | /groups/:id/invite | Bearer | Etsub | Live |
| 44 | GET | /groups/:id/members | Bearer | Etsub | Live |
| 45 | POST | /groups/:id/members | Bearer | Etsub | Stub |
| 46 | DELETE | /groups/:id/members/:id | Bearer | Etsub | Live |
| 47 | PATCH | /groups/:id/members/:id/role | Bearer | Etsub | Live |
| 48 | POST | /groups/:id/start | Bearer | Etsub | Live |
| 49 | POST | /groups/:id/end | Bearer | Etsub | Stub |
| 50 | GET | /groups/:id/dashboard | Bearer | Etsub | Live |
| 51 | GET | /groups/:id/activity | Bearer | Etsub | Live |
| 52 | GET | /groups/:id/contributions | Bearer | Edlawit | Live |
| 53 | GET | /groups/:id/payouts | Bearer | Edlawit | Live |
| 54 | POST | /contributions | Bearer | Edlawit | Live |
| 55 | GET | /contributions | Bearer | Edlawit | Live |
| 56 | GET | /contributions/:id | Bearer | Edlawit | Live |
| 57 | GET | /contributions/pending | Bearer | Edlawit | Live |
| 58 | GET | /contributions/overdue | Bearer | Edlawit | Live |
| 59 | GET | /contributions/stats | Bearer | Edlawit | Live |
| 60 | GET | /contributions/history | Bearer | Edlawit | Live |
| 61 | GET | /contributions/reminders | Bearer | Edlawit | Stub |
| 62 | GET | /members/:id/contributions | Bearer | Edlawit | Live |
| 63 | POST | /contributions/bulk | Bearer | Edlawit | Live |
| 64 | POST | /contributions/manual | Bearer | Edlawit | Live |
| 65 | GET | /payouts | Bearer | Edlawit | Live |
| 66 | GET | /payouts/:id | Bearer | Edlawit | Live |
| 67 | GET | /payouts/history | Bearer | Edlawit | Live |
| 68 | GET | /payouts/schedule | Bearer | Edlawit | Live |
| 69 | GET | /groups/:id/payouts | Bearer | Edlawit | Live |
| 70 | POST | /payouts/:id/approve | Bearer | Edlawit | Live |
| 71 | POST | /payouts/:id/reject | Bearer | Edlawit | Live |
| 72 | GET | /reports/dashboard | Bearer | Edlawit | Live |
| 73 | GET | /reports/user-summary | Bearer | Edlawit | Live |
| 74 | GET | /reports/group-summary | Bearer | Edlawit | Live |
| 75 | GET | /reports/contributions | Bearer | Edlawit | Live |
| 76 | GET | /reports/payouts | Bearer | Edlawit | Live |
| 77 | GET | /reports/financial | Bearer | Edlawit | Live |
| 78 | GET | /reports/analytics | Bearer | Edlawit | Live |
| 79 | GET | /reports/export/pdf | Bearer | Edlawit | Live |
| 80 | GET | /reports/export/excel | Bearer | Edlawit | Live |
| 81 | GET | /notifications | Bearer | Etsub | Stub |
| 82 | GET | /notifications/:id | Bearer | Etsub | Stub |
| 83 | GET | /notifications/unread | Bearer | Etsub | Stub |
| 84 | PATCH | /notifications/:id/read | Bearer | Etsub | Stub |
| 85 | PATCH | /notifications/read-all | Bearer | Etsub | Stub |
| 86 | DELETE | /notifications/:id | Bearer | Etsub | Stub |
| 87 | GET | /notifications/settings | Bearer | Etsub | Stub |
| 88 | PATCH | /notifications/settings | Bearer | Etsub | Stub |
| 89 | POST | /notifications/send | Bearer | Etsub | Stub |
| 90 | GET | /admin/dashboard | Bearer (admin) | Etsub | Stub |
| 91 | GET | /admin/users | Bearer (admin) | Etsub | Stub |
| 92 | GET | /admin/groups | Bearer (admin) | Etsub | Stub |
| 93 | GET | /admin/reports | Bearer (admin) | Etsub | Stub |
| 94 | PATCH | /admin/users/:id/status | Bearer (admin) | Etsub | Stub |
| 95 | DELETE | /admin/users/:id | Bearer (admin) | Etsub | Stub |
| 96 | GET | /admin/logs | Bearer (admin) | Etsub | Stub |
| 97 | GET | /admin/system-health | Bearer (admin) | Etsub | Stub |
| 98 | POST | /admin/backup | Bearer (admin) | Etsub | Stub (501) |
| 99 | POST | /admin/settings | Bearer (admin) | Etsub | Stub (501) |

---

## Notes

- OTP is printed to the server console in dev mode -- check terminal after `/auth/register`
- The `otp_codes` table must exist in the DB before testing register â€” it was created manually
- **OTP pop-up dialog (dev mode)**: In the Flutter app, a branded orange dialog shows the OTP automatically after registration, forgot-password, and change-password flows. It has a copy button. Controlled by `kEnableTestOtpPopup` in `lib/core/utils/test_otp_dialog.dart` -- set to `false` before production.
- **Migration 016**: Run `016_expand_otp_purpose_constraint.sql` to add `password_change`, `phone_update`, and `login` OTP purposes. Required for the change-password OTP flow.
- Stub endpoints return empty responses or 501 until the developer implements them
- The payout fires automatically inside `POST /contributions` when the last member of a cycle pays
- Cycle stays at current number after payout â€” next cycle only starts when `cycle_end_date` has passed AND payout is completed
- `total_cycles` = actual number of members at group start time, not `max_members`
- If you try to pay for a cycle that hasn't started yet, you get a clear error message
- Non-members cannot access group contributions or payouts â€” membership is verified on all group endpoints
- To test admin-only endpoints, set `role = 'system_admin'` in the DB manually
- `Live` = endpoint is wired and has logic Â· `Stub` = route exists but returns empty or 501

## DB columns required (add manually if not yet done)

```sql
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS cycle_end_date DATE;
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS contribution_deadline_days INT NOT NULL DEFAULT 1;
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS total_cycles INT;
```

## Clean test data SQL

```sql
DELETE FROM payouts;
DELETE FROM contributions;
DELETE FROM transactions WHERE type IN ('contribution_debit', 'payout_credit');
DELETE FROM group_members;
DELETE FROM equb_groups;
```

