-- ============================================
-- VERIFY PAYMENT CART SYSTEM - Database Check
-- ============================================
-- Run this to verify your database is ready for the new payment cart system
-- NO CHANGES NEEDED - This is just a verification script

-- ============================================
-- 1. CHECK PAYMENTS TABLE STRUCTURE
-- ============================================
SELECT 
    'Payments Table Structure' as check_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ payment_type (text) - Should allow 'tuition', 'bus', 'canteen'
-- ✓ amount (numeric)
-- ✓ student_id (uuid)
-- ✓ school_id (uuid)
-- ✓ payment_date (date)
-- ✓ payment_method (text)
-- ✓ reference_number (text, nullable)
-- ✓ notes (text, nullable)
-- ✓ recorded_by (uuid, nullable)

-- ============================================
-- 2. CHECK CLASS_FEES TABLE STRUCTURE
-- ============================================
SELECT 
    'Class Fees Table Structure' as check_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'class_fees'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ fee_amount (numeric) - Tuition fee
-- ✓ bus_fee (numeric) - Bus fee
-- ✓ canteen_fee (numeric) - Canteen fee
-- ✓ class (text)
-- ✓ school_id (uuid)
-- ✓ academic_year (text)
-- ✓ term (text)

-- ============================================
-- 3. CHECK STUDENT_FEE_OVERRIDES TABLE
-- ============================================
SELECT 
    'Student Fee Overrides Table Structure' as check_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ uses_bus (boolean)
-- ✓ uses_canteen (boolean)
-- ✓ bus_fee_override (numeric, nullable)
-- ✓ canteen_fee_override (numeric, nullable)
-- ✓ student_id (uuid)
-- ✓ school_id (uuid)
-- ✓ academic_year (text)
-- ✓ term (text)

-- ============================================
-- 4. CHECK PAYMENT_TYPE VALUES
-- ============================================
SELECT 
    'Existing Payment Types' as check_name,
    payment_type,
    COUNT(*) as count
FROM payments
GROUP BY payment_type
ORDER BY payment_type;

-- Expected values: 'tuition', 'bus', 'canteen'
-- If you see other values, they're fine - just informational

-- ============================================
-- 5. VERIFY RLS POLICIES ON PAYMENTS
-- ============================================
SELECT 
    'Payments RLS Policies' as check_name,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'payments';

-- Should have policies for:
-- ✓ SELECT (view payments)
-- ✓ INSERT (record payments)
-- ✓ UPDATE (modify payments)
-- ✓ DELETE (remove payments)

-- ============================================
-- 6. TEST QUERY - Sample Payment Breakdown
-- ============================================
-- This shows how the frontend calculates separate payments
SELECT 
    'Sample Payment Breakdown' as check_name,
    s.full_name,
    s.student_number,
    s.class,
    -- Tuition payments
    COALESCE(SUM(CASE WHEN p.payment_type = 'tuition' THEN p.amount ELSE 0 END), 0) as tuition_paid,
    -- Bus payments
    COALESCE(SUM(CASE WHEN p.payment_type = 'bus' THEN p.amount ELSE 0 END), 0) as bus_paid,
    -- Canteen payments
    COALESCE(SUM(CASE WHEN p.payment_type = 'canteen' THEN p.amount ELSE 0 END), 0) as canteen_paid,
    -- Total paid
    COALESCE(SUM(p.amount), 0) as total_paid
FROM students s
LEFT JOIN payments p ON p.student_id = s.id
WHERE s.status = 'active'
GROUP BY s.id, s.full_name, s.student_number, s.class
LIMIT 5;

-- ============================================
-- 7. CHECK FOR ANY MISSING COLUMNS
-- ============================================
-- Check if payment_type column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'payment_type'
        ) THEN '✓ payment_type column EXISTS'
        ELSE '✗ payment_type column MISSING - Need to run migration!'
    END as payment_type_check;

-- Check if bus_fee column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'class_fees' 
            AND column_name = 'bus_fee'
        ) THEN '✓ bus_fee column EXISTS'
        ELSE '✗ bus_fee column MISSING - Need to run migration!'
    END as bus_fee_check;

-- Check if canteen_fee column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'class_fees' 
            AND column_name = 'canteen_fee'
        ) THEN '✓ canteen_fee column EXISTS'
        ELSE '✗ canteen_fee column MISSING - Need to run migration!'
    END as canteen_fee_check;

-- Check if student_fee_overrides table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_name = 'student_fee_overrides'
        ) THEN '✓ student_fee_overrides table EXISTS'
        ELSE '✗ student_fee_overrides table MISSING - Need to run migration!'
    END as overrides_table_check;

-- ============================================
-- SUMMARY
-- ============================================
-- If all checks show ✓, your database is ready!
-- If any show ✗, you need to run: RUN_FINANCE_MIGRATION.sql

-- ============================================
-- EXPECTED RESULTS:
-- ============================================
-- All checks should return ✓
-- 
-- If you see ✗ for any check, run this migration:
-- RUN_FINANCE_MIGRATION.sql
--
-- The migration adds:
-- - payment_type column to payments table
-- - bus_fee and canteen_fee columns to class_fees table
-- - student_fee_overrides table
-- - Proper RLS policies
