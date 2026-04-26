# Finance System Guide

## Overview

The Finance System allows the headmaster to manage school fees and track student payments efficiently.

## Key Features

### 1. **Set Fees by Class**
- Admin sets a fee amount for each class (e.g., Class 1A = GH₵ 500)
- Can specify term (Term 1, Term 2, Term 3) or leave blank for full year
- Can add description (e.g., "School fees for Term 1")

### 2. **Automatic Billing**
- When a class fee is set, ALL active students in that class are automatically billed
- Each student gets a fee record with:
  - Total Fee Amount
  - Total Paid (starts at 0)
  - Balance (automatically calculated)
  - Payment Status (unpaid/partial/paid)

### 3. **Record Payments**
- Admin can record payments for any student
- Enter payment amount, method (cash, bank transfer, mobile money, cheque)
- Optional reference number for tracking
- System automatically:
  - Updates total paid
  - Recalculates balance
  - Updates payment status

### 4. **Payment Status**
- **Unpaid** (Red badge): Student hasn't paid anything
- **Partial** (Yellow badge): Student has paid some amount but not full
- **Paid** (Green badge): Student has paid the full amount

### 5. **Real-time Statistics**
- **Total Revenue**: All payments collected this academic year
- **Outstanding Fees**: Total balance across all students
- **Collected Today**: Payments received today
- **Collection Rate**: Percentage of fees collected

## Setup Instructions

### Step 1: Run Database Migration

1. Open Supabase SQL Editor
2. Copy and paste the contents of `database-migrations/add-finance-system.sql`
3. Click "Run"
4. Verify tables were created:
   - `class_fees`
   - `student_fees`
   - `payments`

### Step 2: Set Class Fees

1. Login as admin
2. Navigate to **Finance** page
3. Click on **Class Fees** tab
4. Click **Set Class Fee** button
5. Fill in:
   - Class (e.g., "Class 1A")
   - Fee Amount (e.g., 500.00)
   - Term (optional, e.g., "Term 1")
   - Description (optional)
6. Click **Set Fee & Bill Students**
7. All students in that class are now automatically billed!

### Step 3: Record Payments

1. Go to **Student Payments** tab
2. Find the student (use search if needed)
3. Click **Record Payment** button
4. Enter:
   - Payment Amount (e.g., 200.00)
   - Payment Method (cash, bank transfer, etc.)
   - Reference Number (optional, e.g., receipt number)
5. Click **Record Payment**
6. System automatically:
   - Updates total paid
   - Calculates new balance
   - Updates payment status

## How It Works

### Example Scenario

**Step 1: Set Fee**
```
Admin sets: Class 1A = GH₵ 500 (Term 1)
```

**Step 2: Auto-Billing**
```
System creates records for all students in Class 1A:

Student: John Doe
- Total Fee: GH₵ 500.00
- Total Paid: GH₵ 0.00
- Balance: GH₵ 500.00
- Status: Unpaid (Red)
```

**Step 3: First Payment**
```
Admin records: John Doe paid GH₵ 200

System updates:
- Total Fee: GH₵ 500.00
- Total Paid: GH₵ 200.00
- Balance: GH₵ 300.00
- Status: Partial (Yellow)
```

**Step 4: Final Payment**
```
Admin records: John Doe paid GH₵ 300

System updates:
- Total Fee: GH₵ 500.00
- Total Paid: GH₵ 500.00
- Balance: GH₵ 0.00
- Status: Paid (Green)
```

## Database Schema

### class_fees
Stores fee amounts set for each class
```sql
- id: UUID
- school_id: UUID (multi-tenancy)
- class: TEXT (e.g., "Class 1A")
- academic_year: TEXT (e.g., "2024/2025")
- term: TEXT (optional, e.g., "Term 1")
- fee_amount: DECIMAL (e.g., 500.00)
- description: TEXT (optional)
```

### student_fees
Tracks each student's fee obligation and payments
```sql
- id: UUID
- school_id: UUID
- student_id: UUID
- class_fee_id: UUID
- total_fee_amount: DECIMAL
- total_paid: DECIMAL (auto-updated)
- balance: DECIMAL (auto-calculated)
- payment_status: TEXT (auto-calculated: paid/partial/unpaid)
```

### payments
Records each payment transaction
```sql
- id: UUID
- school_id: UUID
- student_fee_id: UUID
- student_id: UUID
- amount: DECIMAL
- payment_date: DATE
- payment_method: TEXT (cash, bank_transfer, mobile_money, cheque)
- reference_number: TEXT (optional)
- recorded_by: UUID (admin who recorded it)
```

## Automatic Features

### 1. Auto-Billing Existing Students
When you set a class fee, the system automatically:
- Finds all active students in that class
- Creates a `student_fees` record for each student
- Sets total_fee_amount to the class fee amount
- Initializes total_paid to 0
- Calculates balance and status

### 2. Auto-Billing New Students
When a new student is added to a class:
- System checks if there are existing class fees for that class
- Automatically creates `student_fees` records for the new student
- Student is immediately billed for all applicable fees

### 3. Auto-Update on Payment
When a payment is recorded:
- System automatically updates `total_paid` in `student_fees`
- Recalculates `balance` (total_fee_amount - total_paid)
- Updates `payment_status`:
  - "paid" if balance = 0
  - "partial" if 0 < balance < total_fee_amount
  - "unpaid" if balance = total_fee_amount

## Multi-Tenancy

All tables include `school_id` for proper isolation:
- Each school can only see their own fees and payments
- Class fees are school-specific
- Student fees are school-specific
- Payments are school-specific

## Features to Add Later

### Phase 2 (Future)
- [ ] Payment history view (see all payments for a student)
- [ ] Print receipts
- [ ] Export payment reports (Excel/PDF)
- [ ] Send payment reminders via SMS
- [ ] Bulk payment import
- [ ] Fee discounts/scholarships
- [ ] Installment plans
- [ ] Late payment penalties

### Phase 3 (Future)
- [ ] Parent portal to view fees and make payments
- [ ] Online payment integration (mobile money API)
- [ ] Financial reports and analytics
- [ ] Budget management
- [ ] Expense tracking

## Troubleshooting

### Students not getting billed automatically
**Check:**
1. Are students marked as "active" in the students table?
2. Does the student's class name exactly match the class fee class name?
3. Does the student have the correct school_id?

**Solution:**
Run this query to manually bill students:
```sql
INSERT INTO public.student_fees (
  school_id, student_id, class_fee_id, class, 
  academic_year, term, total_fee_amount
)
SELECT 
  cf.school_id, s.id, cf.id, cf.class,
  cf.academic_year, cf.term, cf.fee_amount
FROM public.class_fees cf
JOIN public.students s ON s.class = cf.class AND s.school_id = cf.school_id
WHERE s.status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM public.student_fees sf 
    WHERE sf.student_id = s.id AND sf.class_fee_id = cf.id
  );
```

### Payment not updating balance
**Check:**
1. Is the payment record created successfully?
2. Are the triggers enabled?

**Solution:**
Manually recalculate totals:
```sql
UPDATE public.student_fees sf
SET total_paid = (
  SELECT COALESCE(SUM(amount), 0)
  FROM public.payments p
  WHERE p.student_fee_id = sf.id
);
```

## Best Practices

1. **Set fees at the beginning of each term**
2. **Record payments immediately** when received
3. **Always include reference numbers** for non-cash payments
4. **Regularly check outstanding fees** to follow up with parents
5. **Export reports** at the end of each term for accounting

## Support

If you encounter any issues:
1. Check the browser console for errors
2. Check Supabase logs
3. Verify database triggers are working
4. Contact support with error details

---

**Finance System is now ready to use!** 🎉
