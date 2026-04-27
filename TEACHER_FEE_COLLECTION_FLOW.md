# Teacher Fee Collection System - Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     TEACHER FEE COLLECTION SYSTEM                │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│                  │         │                  │         │                  │
│   ADMIN          │         │   TEACHER        │         │   DATABASE       │
│   (Settings)     │         │   (Dashboard)    │         │   (Supabase)     │
│                  │         │                  │         │                  │
└──────────────────┘         └──────────────────┘         └──────────────────┘
```

---

## Flow 1: Feature Setup (Admin)

```
┌─────────────┐
│   ADMIN     │
│   LOGIN     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│  Settings → Profile Tab     │
│  Enable Teacher Fee         │
│  Collection Toggle          │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Save School Settings       │
│  (Updates database)         │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Settings → Teachers Tab    │
│  Assign Teachers to Classes │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  ✅ SYSTEM READY            │
└─────────────────────────────┘
```

---

## Flow 2: Fee Collection (Teacher)

```
┌─────────────┐
│  TEACHER    │
│   LOGIN     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│  Sidebar → Fee Collection   │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  View Students in           │
│  Assigned Class             │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Select Student             │
│  Click "Collect Fee"        │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Dialog Opens:              │
│  - Select Type (Bus/Canteen)│
│  - Amount (Pre-filled)      │
│  - Add Notes (Optional)     │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Click "Record Collection"  │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  DATABASE:                  │
│  INSERT INTO                │
│  teacher_fee_collections    │
│  status = 'pending'         │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  ✅ Collection Recorded     │
│  Status: PENDING            │
└─────────────────────────────┘
```

---

## Flow 3: Admin Confirmation

```
┌─────────────┐
│   ADMIN     │
│   LOGIN     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│  Finance → Teacher          │
│  Collections Tab            │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  View Pending Collections   │
│  (Teacher, Student, Amount) │
└──────┬──────────────────────┘
       │
       ├──────────────────┬──────────────────┐
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   CONFIRM    │   │    REJECT    │   │   IGNORE     │
└──────┬───────┘   └──────┬───────┘   └──────────────┘
       │                  │
       ▼                  ▼
┌──────────────────┐   ┌──────────────────┐
│ DATABASE:        │   │ DATABASE:        │
│ UPDATE status    │   │ UPDATE status    │
│ = 'confirmed'    │   │ = 'rejected'     │
└──────┬───────────┘   │ + reason         │
       │               └──────────────────┘
       ▼
┌──────────────────┐
│ TRIGGER FIRES:   │
│ create_payment_  │
│ from_collection()│
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ INSERT INTO      │
│ payments         │
│ (auto-created)   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ UPDATE           │
│ student_fees     │
│ (balance reduced)│
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ ✅ PAYMENT       │
│    RECORDED      │
└──────────────────┘
```

---

## Flow 4: Teacher Views Status

```
┌─────────────┐
│  TEACHER    │
│   LOGIN     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│  Fee Collection →           │
│  My Collections Tab         │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  View Collection History:   │
│                             │
│  🟠 PENDING                 │
│     Waiting for admin       │
│                             │
│  🟢 CONFIRMED               │
│     Payment created         │
│                             │
│  🔴 REJECTED                │
│     Reason: "Amount wrong"  │
└─────────────────────────────┘
```

---

## Database Schema Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                      DATABASE TABLES                          │
└──────────────────────────────────────────────────────────────┘

┌─────────────────┐
│  school_settings│
│  ─────────────  │
│  id             │
│  school_id      │
│  enable_teacher_│
│  fee_collection │◄─── Admin Toggle
└─────────────────┘

┌─────────────────┐         ┌─────────────────┐
│    teachers     │         │    students     │
│  ─────────────  │         │  ─────────────  │
│  id             │         │  id             │
│  user_id        │         │  full_name      │
│  class_assigned │         │  class          │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │                           │
         │    ┌──────────────────────┴────────────────────┐
         │    │                                            │
         │    │  teacher_fee_collections                   │
         │    │  ────────────────────────────              │
         └────┼─►teacher_id                                │
              ├─►student_id                                │
              │  collection_type (bus/canteen)             │
              │  amount                                    │
              │  status (pending/confirmed/rejected)       │
              │  notes                                     │
              │  rejection_reason                          │
              │  payment_id ◄──────────┐                   │
              └────────────────────────┼───────────────────┘
                                       │
                                       │
                              ┌────────┴────────┐
                              │    payments     │
                              │  ─────────────  │
                              │  id             │
                              │  student_id     │
                              │  amount         │
                              │  payment_type   │
                              │  payment_date   │
                              └─────────────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  student_fees   │
                              │  ─────────────  │
                              │  student_id     │
                              │  total_paid     │
                              │  balance        │
                              └─────────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                           │
└─────────────────────────────────────────────────────────────┘

1. AUTHENTICATION
   ├─► User must be logged in
   └─► JWT token validated

2. ROLE-BASED ACCESS
   ├─► Teachers: Can INSERT collections
   ├─► Admins: Can UPDATE collections
   └─► Users: Can SELECT their school's data

3. ROW LEVEL SECURITY (RLS)
   ├─► All queries filtered by school_id
   ├─► Teachers see only their collections
   └─► Admins see all collections

4. CLASS RESTRICTION
   ├─► Teacher can only collect from assigned class
   └─► Validated in frontend and database

5. STATUS VALIDATION
   ├─► Only 'pending' can be confirmed/rejected
   └─► Trigger validates status change

6. AUDIT TRAIL
   ├─► All actions logged with timestamps
   ├─► confirmed_by tracks admin
   └─► created_at tracks collection time
```

---

## User Interface Map

```
┌─────────────────────────────────────────────────────────────┐
│                      ADMIN VIEW                              │
└─────────────────────────────────────────────────────────────┘

Settings Page
├─► Profile Tab
│   └─► Teacher Fee Collection Toggle ☑
│
└─► Teachers Tab
    └─► Assign Classes to Teachers

Finance Page
├─► Payments Tab (existing)
├─► Class Fees Tab (existing)
└─► Teacher Collections Tab (NEW!)
    ├─► Summary Cards
    │   ├─► Pending Amount
    │   ├─► Confirmed Amount
    │   └─► Total Collected
    │
    └─► Tabs
        ├─► Pending (Confirm/Reject)
        ├─► Confirmed (View only)
        └─► Rejected (View only)

┌─────────────────────────────────────────────────────────────┐
│                     TEACHER VIEW                             │
└─────────────────────────────────────────────────────────────┘

Sidebar
└─► Fee Collection (NEW!)

Fee Collection Page
├─► Summary Cards
│   ├─► Total Students
│   ├─► Pending Confirmation
│   ├─► Confirmed
│   └─► Total Collected
│
└─► Tabs
    ├─► Collect Fees
    │   ├─► Student List
    │   └─► Collect Fee Button → Dialog
    │
    └─► My Collections
        └─► History with Status
```

---

## Status Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                   COLLECTION STATUS                          │
└─────────────────────────────────────────────────────────────┘

    CREATED
       │
       ▼
  ┌─────────┐
  │ PENDING │ ◄─── Teacher records collection
  └────┬────┘
       │
       ├──────────────────┬──────────────────┐
       │                  │                  │
       ▼                  ▼                  ▼
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │CONFIRMED │      │ REJECTED │      │ PENDING  │
  │          │      │          │      │(waiting) │
  └────┬─────┘      └──────────┘      └──────────┘
       │
       ▼
  ┌──────────┐
  │ PAYMENT  │
  │ CREATED  │
  └──────────┘
       │
       ▼
  ┌──────────┐
  │ BALANCE  │
  │ UPDATED  │
  └──────────┘

Legend:
🟠 PENDING   - Waiting for admin confirmation
🟢 CONFIRMED - Admin received money, payment created
🔴 REJECTED  - Admin rejected with reason
```

---

## Summary

This system provides a complete workflow for teachers to collect fees with admin oversight, ensuring:

✅ **Control**: Admin must confirm before recording
✅ **Transparency**: Full audit trail
✅ **Security**: RLS policies and role-based access
✅ **Flexibility**: Can be enabled/disabled
✅ **Accountability**: Track who, when, and status

**Next Step**: Follow `TEACHER_FEE_COLLECTION_SETUP.md` to deploy!
