# Production Deployment Checklist

Complete guide for deploying your School Management System to production with a fresh database.

## 📋 Pre-Deployment Checklist

### 1. Environment Setup
- [ ] Supabase project created and configured
- [ ] Service role key added to environment variables
- [ ] Production URL configured: `https://academix-man.netlify.app`
- [ ] Email templates configured in Supabase (ash-colored buttons)
- [ ] Redirect URLs set to production domain

### 2. Database Preparation
- [ ] All database migrations run successfully
- [ ] RLS policies enabled and tested
- [ ] Storage buckets created for logos/signatures
- [ ] Triggers and functions properly set up

## 🗑️ Database Reset (Fresh Start)

### Option 1: Manual Reset (Recommended)
Follow the step-by-step guide in `MANUAL_DATABASE_RESET_GUIDE.md`:

1. **Delete all data** (run queries one by one in Supabase SQL Editor)
2. **Set up student ID generation** (automatic school-specific prefixes)
3. **Set up staff ID generation** (automatic school-specific prefixes)
4. **Verify clean state** (all tables empty, triggers active)

### Option 2: Automated Reset
Run the complete script: `PRODUCTION_FRESH_START.sql`

**Result:** Clean database ready for new school registrations

## 🏫 School Registration Process

### Current Method: Manual Registration

#### Step 1: Register School in Database
```sql
INSERT INTO public.school_settings (
  school_name,
  address,
  phone,
  email,
  current_term,
  current_academic_year
) VALUES (
  'School Name Here',
  'School Address',
  '+233-XX-XXX-XXXX',
  'admin@school.edu.gh',
  'Term 1',
  '2024/2025'
);
```

#### Step 2: Create Admin Account
1. Go to **Supabase > Authentication > Users**
2. Click **Add User**
3. Enter email and password
4. ✅ Check "Email Confirm"
5. Copy the generated User ID

#### Step 3: Link Admin to School
```sql
INSERT INTO public.users (
    id,
    email,
    role,
    full_name,
    school_id
) VALUES (
    'USER_ID_FROM_STEP_2',
    'admin@school.edu.gh',
    'admin',
    'Admin Full Name',
    (SELECT id FROM public.school_settings WHERE school_name = 'School Name Here')
);
```

#### Step 4: Test Login
- Go to production URL
- Login with admin credentials
- Verify dashboard loads correctly
- Test adding a student (check ID generation)

**Detailed Guide:** See `NEW_SCHOOL_REGISTRATION_PROCESS.md`

## 🎓 Student & Staff ID Generation

### How It Works
Each school gets unique ID prefixes based on their school name:

| School Name | Prefix | Student IDs | Staff IDs |
|-------------|--------|-------------|-----------|
| Greenwood Academy | GRE | GRE0001, GRE0002... | GRE0001, GRE0002... |
| St. Mary's College | STM | STM0001, STM0002... | STM0001, STM0002... |
| International School | INT | INT0001, INT0002... | INT0001, INT0002... |

### Prefix Generation Rules
- Takes first 3 letters of school name
- Removes spaces and special characters
- Converts to uppercase
- Example: "Nhyiaeso International School" → "NHY"

### Numbering
- School-specific (each school starts from 0001)
- Sequential within each school
- Automatic generation on student/staff creation
- No manual intervention needed

## 🔧 System Features

### Multi-Tenancy
- ✅ Each school sees only their data
- ✅ Complete data isolation
- ✅ Secure RLS policies
- ✅ School-specific ID generation

### Core Modules
1. **Dashboard** - Overview and quick stats
2. **Registrar** - Student & staff management
3. **Attendance** - Daily attendance tracking
4. **Academic** - Grades and report cards
5. **Finance** - Fee management and payments
6. **Settings** - School configuration

### User Roles
- **Admin** - Full system access for school
- **Teacher** - Class-specific access (students, grades, attendance)
- **Staff** - Limited access based on position

## 🚨 Known Issues & Solutions

### Issue 1: Teacher Login Creation Fails
**Symptom:** "Staff Added with Warning - login account creation failed"

**Cause:** API endpoint not responding or server not running

**Solutions:**
1. **Check if server is running** on Netlify
2. **Verify environment variables** (SUPABASE_SERVICE_ROLE_KEY)
3. **Manual fix:** Use `FIX_DANIEL_GYAN_ACCOUNT.sql` to create account manually
4. **Alternative:** Delete staff record and recreate after fixing server

### Issue 2: Student IDs Have Wrong Prefix
**Symptom:** Nhyiaeso students getting "MOU" instead of "NHY"

**Solution:** Run `FIX_SCHOOL_PREFIX_GENERATION.sql`

### Issue 3: Cannot See Other School's Data (This is correct!)
**Symptom:** Admin can only see their own school's data

**Status:** ✅ This is the correct behavior (multi-tenancy working)

## 📊 Post-Deployment Testing

### Test Checklist
- [ ] Admin can login successfully
- [ ] Dashboard loads with correct school name
- [ ] Can add students (verify ID generation)
- [ ] Can add staff (verify ID generation)
- [ ] Can create teacher with login account
- [ ] Teacher can login and see assigned class
- [ ] Attendance system works
- [ ] Academic grading works
- [ ] Finance system works
- [ ] Settings can be updated
- [ ] Password reset works
- [ ] Email change works

### Test Data
Create test records to verify:
1. **1 Student** - Check ID format (e.g., GRE0001)
2. **1 Teacher** - Check login creation and class assignment
3. **1 Attendance Record** - Verify teacher can mark attendance
4. **1 Grade Entry** - Verify teacher can enter grades
5. **1 Fee Payment** - Verify finance system works

## 🎯 Production Readiness Criteria

### Must Have ✅
- [x] Database completely reset
- [x] Student ID generation working
- [x] Staff ID generation working
- [x] Multi-tenancy enforced
- [x] RLS policies active
- [x] Email system configured
- [x] Password reset working

### Should Have ⚠️
- [ ] Server API endpoints working (teacher creation)
- [ ] Error logging configured
- [ ] Backup strategy in place
- [ ] Documentation for schools

### Nice to Have 💡
- [ ] Automated school registration form
- [ ] Welcome email automation
- [ ] Usage analytics
- [ ] Performance monitoring

## 📚 Documentation Files

### Setup & Configuration
- `MANUAL_DATABASE_RESET_GUIDE.md` - Step-by-step database reset
- `PRODUCTION_FRESH_START.sql` - Automated reset script
- `NEW_SCHOOL_REGISTRATION_PROCESS.md` - How to register schools

### Troubleshooting
- `DIAGNOSE_API_ISSUE.sql` - Check API problems
- `FIX_DANIEL_GYAN_ACCOUNT.sql` - Fix failed teacher accounts
- `FIX_SCHOOL_PREFIX_GENERATION.sql` - Fix student ID prefixes

### Reference
- `SUPABASE_EMAIL_CONFIGURATION.md` - Email setup guide
- `ACCOUNT_MANAGEMENT_GUIDE.md` - Password reset, email change
- `TEACHER_CLASS_ASSIGNMENT_GUIDE.md` - Teacher management

## 🚀 Deployment Steps Summary

1. **Reset Database** → Use manual guide or automated script
2. **Verify Clean State** → All tables empty, triggers active
3. **Register First School** → Follow school registration process
4. **Test Everything** → Use test checklist above
5. **Fix Any Issues** → Use troubleshooting guides
6. **Go Live** → Share production URL with schools

## 📞 Support Information

### For School Admins
- Production URL: `https://academix-man.netlify.app`
- Support Email: [Your support email]
- Documentation: [Link to user guides]

### For Developers
- Supabase Dashboard: [Your Supabase project URL]
- GitHub Repo: [Your repo URL]
- Environment Variables: Check `.env` file

## ✅ Final Checklist

Before going live:
- [ ] Database reset completed
- [ ] At least one test school registered
- [ ] All core features tested
- [ ] Known issues documented
- [ ] Support process defined
- [ ] Backup strategy in place
- [ ] Monitoring configured

**Status:** Ready for production deployment! 🎉

## 🔄 Next Steps After Deployment

1. **Monitor first school** - Watch for any issues
2. **Gather feedback** - Ask about user experience
3. **Fix critical bugs** - Address any blocking issues
4. **Add more schools** - Scale gradually
5. **Build automation** - School registration form
6. **Enhance features** - Based on feedback

---

**Last Updated:** May 6, 2026
**System Version:** 1.0.0 Production Ready
**Database Status:** Clean and ready for schools