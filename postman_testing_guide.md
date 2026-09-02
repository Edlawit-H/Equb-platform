# Equb API - Postman Testing Guide

Backend: `https://equb-backend-t6h8.onrender.com`
API Prefix: `https://equb-backend-t6h8.onrender.com/api/v1`

---

## Postman Environment Variables

| Variable | Value | How to get it |
|---|---|---|
| `baseUrl` | `https://equb-backend-t6h8.onrender.com/api/v1` | Manual |
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

## Phase 1 - Health Check

### 1.1 Server Health
```
Method: GET
URL:    https://equb-backend-t6h8.onrender.com/health
Auth:   None
```
Expected 200:
```json
{ "status": "ok", "db": "ok", "uptime": 14.52 }
```
> Render free tier sleeps after 15 min of inactivity. First request may take 30-60s to wake up.

---

## Phase 2 - Authentication

### 2.1 Register Admin
```
Method: POST
URL:    {{baseUrl}}/auth/register
Auth:   None
Body:   { "full_name": "Edlawit Admin", "phone_number": "+251911111111", "password": "Password123!" }
```
Expected 200: `{ "message": "OTP sent", "data": { "otp": "123456" } }`
> OTP is returned in the response data (dev mode) and printed to server terminal. The Flutter app shows it in an orange popup in debug builds.

### 2.2 Register Member B
```
Method: POST
URL:    {{baseUrl}}/auth/register
Body:   { "full_name": "Etsub Member", "phone_number": "+251922222222", "password": "Password123!" }
```

### 2.3 Register Member C
```
Method: POST
URL:    {{baseUrl}}/auth/register
Body:   { "full_name": "Hana Member", "phone_number": "+251933333333", "password": "Password123!" }
```

### 2.4 Verify OTP - Admin
```
Method: POST
URL:    {{baseUrl}}/auth/verify-otp
Auth:   None
Body:
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
  "data": { "user": { ... }, "accessToken": "eyJ...", "refreshToken": "eyJ..." }
}
```
> Save `data.accessToken` -> `token_admin`

### 2.5 Verify OTP - Member B
Same as 2.4 using `+251922222222` / `Etsub Member`. Save token -> `token_b`

### 2.6 Verify OTP - Member C
Same as 2.4 using `+251933333333` / `Hana Member`. Save token -> `token_c`

### 2.7 Login
```
Method: POST
URL:    {{baseUrl}}/auth/login
Body:   { "phone_number": "+251911111111", "password": "Password123!" }
```
Expected 200 - returns `accessToken` and `refreshToken`.

### 2.8 Forgot Password
```
Method: POST
URL:    {{baseUrl}}/auth/forgot-password
Body:   { "phone_number": "+251911111111" }
```
Expected 200: `{ "message": "OTP sent", "otp": "123456" }`

### 2.9 Reset Password
```
Method: POST
URL:    {{baseUrl}}/auth/reset-password
Body:   { "phone_number": "+251911111111", "otp_code": "123456", "new_password": "NewPassword123!" }
```
Expected 200: `{ "message": "Password updated successfully" }`

### 2.10 Get My Profile
```
Method: GET
URL:    {{baseUrl}}/users/me
Auth:   Bearer {{token_admin}}
```

### 2.11 Update My Profile
```
Method: PATCH
URL:    {{baseUrl}}/users/me
Auth:   Bearer {{token_admin}}
Body:   { "full_name": "Edlawit Admin Updated" }
```

---

## Phase 3 - Change Password (2-step OTP flow)

### 3.1 Request OTP
```
Method: POST
URL:    {{baseUrl}}/users/me/password/send-otp
Auth:   Bearer {{token_admin}}
Body:   { "current_password": "Password123!", "new_password": "NewPassword456!" }
```
Expected 200:
```json
{ "message": "Verification code sent successfully", "masked_phone": "+251911****111", "otp": "123456" }
```
> OTP shown in response (dev), terminal, and app popup.

### 3.2 Confirm Change
```
Method: PATCH
URL:    {{baseUrl}}/users/me/password
Auth:   Bearer {{token_admin}}
Body:   { "current_password": "Password123!", "new_password": "NewPassword456!", "otp_code": "123456" }
```
Expected 200: `{ "message": "Password changed successfully" }`

---

## Phase 4 - Wallet & Transactions

### 4.1 Get Wallet Balance
```
Method: GET
URL:    {{baseUrl}}/transactions/wallet
Auth:   Bearer {{token_admin}}
```

### 4.2 Top Up Wallet
```
Method: POST
URL:    {{baseUrl}}/transactions/top-up
Auth:   Bearer {{token_admin}}
Body:   { "amount": 10000 }
```
Expected 200: `{ "message": "Wallet topped up successfully", "new_balance": "10000.00" }`
> Repeat for token_b (5000) and token_c (5000).

### 4.3 Get All Transactions
```
Method: GET
URL:    {{baseUrl}}/transactions
Auth:   Bearer {{token_admin}}
```

### 4.4 Filter by Date Range
```
Method: GET
URL:    {{baseUrl}}/transactions?from=2026-01-01&to=2026-12-31
Auth:   Bearer {{token_admin}}
```

### 4.5 Get Transaction Stats
```
Method: GET
URL:    {{baseUrl}}/transactions/stats
Auth:   Bearer {{token_admin}}
```

### 4.6 Get Group Transactions
```
Method: GET
URL:    {{baseUrl}}/transactions/group/{{group_id}}
Auth:   Bearer {{token_admin}}
```

---

## Phase 5 - Group Management

### 5.1 Create Group
```
Method: POST
URL:    {{baseUrl}}/groups
Auth:   Bearer {{token_admin}}
Body:
{
  "group_name": "Fast Track Equb",
  "description": "Test group for 3 members",
  "contribution_amount": 1000,
  "cycle_duration": 7,
  "max_members": 3,
  "selection_mode": "positional"
}
```
Expected 201 - returns `group_id` and `invitation_code`.
> Save `data.group_id` -> `group_id` and `data.invitation_code` -> `invite_code`
> `selection_mode`: `positional` (default) or `random`
> `contribution_deadline_days`: 1 (default) or 2

### 5.2 Get My Groups
```
Method: GET
URL:    {{baseUrl}}/groups
Auth:   Bearer {{token_admin}}
```

### 5.3 Get Group By ID
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}
Auth:   Bearer {{token_admin}}
```

### 5.4 Member B Joins
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_b}}
Body:   (empty)
```
Expected 200 - returns `member_id`. Save -> `member_id_b`

### 5.5 Member C Joins
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_c}}
Body:   (empty)
```
Save `data.member_id` -> `member_id_c`

### 5.6 Get Group Members
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/members
Auth:   Bearer {{token_admin}}
```

### 5.7 Start Group
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/start
Auth:   Bearer {{token_admin}}
Body:   (empty)
```
Expected 200 - status becomes `active`, contributions for cycle 1 are created.
> total_cycles = number of members who joined, NOT max_members.
> Once started, no new members can join.

### 5.8 Get Group Payout Schedule (NEW)
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/schedule
Auth:   Bearer {{token_admin}}
```
Expected 200:
```json
{
  "data": {
    "group_name": "Fast Track Equb",
    "current_cycle": 1,
    "total_cycles": 3,
    "cycle_duration": 7,
    "estimated_payout_per_cycle": 3000,
    "schedule": [
      {
        "cycle_number": 1,
        "recipient_name": "Edlawit Admin",
        "projected_date": "2026-08-14",
        "payout_amount": 3000,
        "status": "current"
      },
      {
        "cycle_number": 2,
        "recipient_name": "Etsub Member",
        "projected_date": "2026-08-21",
        "payout_amount": 3000,
        "status": "upcoming"
      },
      {
        "cycle_number": 3,
        "recipient_name": "Hana Member",
        "projected_date": "2026-08-28",
        "payout_amount": 3000,
        "status": "upcoming"
      }
    ]
  }
}
```
> `projected_date` = `start_date + (cycle - 1) * cycle_duration` days.
> `status`: `completed` | `current` | `upcoming`

### 5.9 Get Group Dashboard
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/dashboard
Auth:   Bearer {{token_admin}}
```

### 5.10 Get Group Activity Log
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/activity
Auth:   Bearer {{token_admin}}
```

### 5.11 Join Started Group (Edge Case - must fail)
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/join
Auth:   Bearer {{token_admin}}
```
Expected 400 - cannot join a group that has already started.

### 5.12 Leave Active Group (Edge Case - must fail)
```
Method: POST
URL:    {{baseUrl}}/groups/{{group_id}}/leave
Auth:   Bearer {{token_b}}
```
Expected 400 - cannot leave an active group.

---

## Phase 6 - Contributions

### 6.1 Get My Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
```

### 6.2 Get Pending Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions/pending
Auth:   Bearer {{token_admin}}
```

### 6.3 Get Overdue Contributions
```
Method: GET
URL:    {{baseUrl}}/contributions/overdue
Auth:   Bearer {{token_admin}}
```

### 6.4 Admin Pays - Cycle 1 (1 of 3)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
Body:   { "group_id": "{{group_id}}", "cycle_number": 1 }
```
Expected 200 - wallet debited 1000. 1/3 paid. No payout yet.

### 6.5 Member B Pays - Cycle 1 (2 of 3)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_b}}
Body:   { "group_id": "{{group_id}}", "cycle_number": 1 }
```

### 6.6 Member C Pays - Cycle 1 (3 of 3 - AUTO PAYOUT FIRES)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_c}}
Body:   { "group_id": "{{group_id}}", "cycle_number": 1 }
```
> All 3 paid -> payout fires automatically to Admin (position 1). 3000 ETB credited.
> Cycle number stays at 1. Next cycle only starts after cycle_end_date passes.

### 6.7 Duplicate Contribution (Edge Case - must fail)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_admin}}
Body:   { "group_id": "{{group_id}}", "cycle_number": 1 }
```
Expected 409:
```json
{ "status": "error", "message": "This contribution has already been paid" }
```
> Flutter app shows user-friendly message: "You have already contributed for this cycle."

### 6.8 Pay Wrong Cycle (Edge Case - must fail)
```
Method: POST
URL:    {{baseUrl}}/contributions
Auth:   Bearer {{token_b}}
Body:   { "group_id": "{{group_id}}", "cycle_number": 2 }
```
Expected 400 - cycle 2 has not started yet.

### 6.9 Get Group Contributions
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/contributions
Auth:   Bearer {{token_admin}}
```

---

## Phase 7 - Payouts

### 7.1 Get My Payouts
```
Method: GET
URL:    {{baseUrl}}/payouts
Auth:   Bearer {{token_admin}}
```
Expected 200 - shows the cycle 1 payout of 3000 ETB for Admin.

### 7.2 Get Payout History
```
Method: GET
URL:    {{baseUrl}}/payouts/history
Auth:   Bearer {{token_admin}}
```

### 7.3 Get My Payout Schedule (user-scoped)
```
Method: GET
URL:    {{baseUrl}}/payouts/schedule
Auth:   Bearer {{token_admin}}
```
> Returns the current user's own turn info per group. For full group timeline use 5.8.

### 7.4 Get Group Payouts
```
Method: GET
URL:    {{baseUrl}}/groups/{{group_id}}/payouts
Auth:   Bearer {{token_admin}}
```

### 7.5 Get Single Payout
```
Method: GET
URL:    {{baseUrl}}/payouts/{{payout_id}}
Auth:   Bearer {{token_admin}}
```

### 7.6 Approve Payout (Admin)
```
Method: POST
URL:    {{baseUrl}}/payouts/{{payout_id}}/approve
Auth:   Bearer {{token_admin}}
```

### 7.7 Reject Payout (Admin)
```
Method: POST
URL:    {{baseUrl}}/payouts/{{payout_id}}/reject
Auth:   Bearer {{token_admin}}
```

---

## Phase 8 - Reports

### 8.1 Home Dashboard
```
Method: GET
URL:    {{baseUrl}}/reports/dashboard
Auth:   Bearer {{token_admin}}
```

### 8.2 User Summary
```
Method: GET
URL:    {{baseUrl}}/reports/user-summary
Auth:   Bearer {{token_admin}}
```

### 8.3 Group Summary
```
Method: GET
URL:    {{baseUrl}}/reports/group-summary?group_id={{group_id}}
Auth:   Bearer {{token_admin}}
```

### 8.4 Analytics
```
Method: GET
URL:    {{baseUrl}}/reports/analytics
Auth:   Bearer {{token_admin}}
```

---

## Phase 9 - Notifications

### 9.1 Get All Notifications
```
Method: GET
URL:    {{baseUrl}}/notifications
Auth:   Bearer {{token_admin}}
```

### 9.2 Get Unread Count
```
Method: GET
URL:    {{baseUrl}}/notifications/unread
Auth:   Bearer {{token_admin}}
```

### 9.3 Mark All as Read
```
Method: PATCH
URL:    {{baseUrl}}/notifications/read-all
Auth:   Bearer {{token_admin}}
```

### 9.4 Get / Update Notification Settings
```
Method: GET / PATCH
URL:    {{baseUrl}}/notifications/settings
Auth:   Bearer {{token_admin}}
```

---

## Phase 10 - Admin Panel

> Requires `role = 'system_admin'` in DB:
> `UPDATE users SET role = 'system_admin' WHERE phone_number = '+251911111111';`

### 10.1 Platform Dashboard
```
Method: GET
URL:    {{baseUrl}}/admin/dashboard
Auth:   Bearer {{token_admin}}
```

### 10.2 List All Users
```
Method: GET
URL:    {{baseUrl}}/admin/users
Auth:   Bearer {{token_admin}}
```

### 10.3 List All Groups
```
Method: GET
URL:    {{baseUrl}}/admin/groups
Auth:   Bearer {{token_admin}}
```

### 10.4 Suspend User
```
Method: PATCH
URL:    {{baseUrl}}/admin/users/{{member_id_b}}/status
Auth:   Bearer {{token_admin}}
Body:   { "status": "suspended" }
```

---

## Complete Endpoint Reference

| # | Method | Endpoint | Status |
|---|---|---|---|
| 1 | GET | /health | Live |
| 2 | POST | /auth/register | Live |
| 3 | POST | /auth/verify-otp | Live |
| 4 | POST | /auth/login | Live |
| 5 | POST | /auth/forgot-password | Live |
| 6 | POST | /auth/reset-password | Live |
| 7 | GET | /users/me | Live |
| 8 | PATCH | /users/me | Live |
| 9 | POST | /users/me/password/send-otp | Live |
| 10 | PATCH | /users/me/password | Live |
| 11 | GET | /transactions/wallet | Live |
| 12 | POST | /transactions/top-up | Live |
| 13 | GET | /transactions | Live |
| 14 | GET | /transactions/stats | Live |
| 15 | GET | /transactions/group/:groupId | Live |
| 16 | POST | /groups | Live |
| 17 | GET | /groups | Live |
| 18 | GET | /groups/:id | Live |
| 19 | PATCH | /groups/:id | Live |
| 20 | DELETE | /groups/:id | Live |
| 21 | POST | /groups/:id/join | Live |
| 22 | POST | /groups/:id/leave | Live |
| 23 | GET | /groups/:id/members | Live |
| 24 | POST | /groups/:id/start | Live |
| 25 | GET | /groups/:id/contributions | Live |
| 26 | GET | /groups/:id/payouts | Live |
| 27 | GET | /groups/:id/schedule | Live |
| 28 | POST | /contributions | Live |
| 29 | GET | /contributions | Live |
| 30 | GET | /contributions/pending | Live |
| 31 | GET | /contributions/overdue | Live |
| 32 | GET | /contributions/stats | Live |
| 33 | POST | /contributions/bulk | Live |
| 34 | POST | /contributions/manual | Live |
| 35 | GET | /payouts | Live |
| 36 | GET | /payouts/:id | Live |
| 37 | GET | /payouts/history | Live |
| 38 | GET | /payouts/schedule | Live |
| 39 | POST | /payouts/:id/approve | Live |
| 40 | POST | /payouts/:id/reject | Live |
| 41 | GET | /reports/dashboard | Live |
| 42 | GET | /reports/user-summary | Live |
| 43 | GET | /reports/group-summary | Live |
| 44 | GET | /reports/analytics | Live |
| 45 | GET | /notifications | Live |
| 46 | GET | /notifications/unread | Live |
| 47 | PATCH | /notifications/read-all | Live |
| 48 | GET | /notifications/settings | Live |
| 49 | PATCH | /notifications/settings | Live |
| 50 | GET | /admin/dashboard | Stub (501) |
| 51 | GET | /admin/users | Stub (501) |
| 52 | GET | /admin/groups | Stub (501) |
| 53 | PATCH | /admin/users/:id/status | Stub (501) |
| 54 | DELETE | /admin/users/:id | Stub (501) |
| 55 | GET | /admin/logs | Stub (501) |

---

## Notes

- **Render cold start**: first request after 15 min idle may take 30-60s.
- **OTP**: returned in response body (dev), printed to server terminal, and shown as orange popup in Flutter debug builds. Automatically hidden in release builds.
- **Migration 016**: run `016_expand_otp_purpose_constraint.sql` before testing change-password OTP flow.
- **Duplicate contribution**: backend returns 409 with `"This contribution has already been paid"`. Flutter shows user-friendly: `"You have already contributed for this cycle."`
- **Payout trigger**: fires automatically when all members in the current cycle have paid. Cycle number does NOT advance until `cycle_end_date` passes.
- **total_cycles** = members present at group start, not `max_members`.
- **Group schedule endpoint** (`GET /groups/:id/schedule`) returns the full rotation timeline with projected dates calculated as `start_date + (cycle-1) * cycle_duration` days.
- `Live` = endpoint is wired and functional. `Stub (501)` = route exists but returns 501.

## DB setup (run once on fresh DB)

```sql
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS cycle_end_date DATE;
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS contribution_deadline_days INT NOT NULL DEFAULT 1;
ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS total_cycles INT;
```

## Clean test data

```sql
DELETE FROM payouts;
DELETE FROM contributions;
DELETE FROM transactions WHERE type IN ('contribution_debit', 'payout_credit');
DELETE FROM group_members;
DELETE FROM equb_groups;
```