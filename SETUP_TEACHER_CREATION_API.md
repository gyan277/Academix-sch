# Setup Teacher Creation API

## 🎯 **Problem Solved**

The frontend can't create user accounts directly due to security restrictions. I've created a server-side API endpoint that can create teacher login accounts using the Supabase service role key.

## 🔧 **Setup Steps**

### **Step 1: Add Service Role Key to Environment**

1. **Go to your Supabase project dashboard**
2. **Navigate to Settings → API**
3. **Copy the "service_role" key** (not the anon key)
4. **Add it to your `.env` file:**

```env
# Add this line to your .env file
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhYXh1Y2t0cHF3cmVxbm52cnB6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njg1MTUzOCwiZXhwIjoyMDkyNDI3NTM4fQ.d1B8uXCOn0sy3gBgwFlW5yqOVS6Kce7cgDMxOJ6GQY8
```

### **Step 2: Restart the Development Server**

```bash
# Stop the current server (Ctrl+C)
# Then restart
pnpm dev
```

### **Step 3: Test Teacher Creation**

1. **Go to Registrar → Staff**
2. **Click "Add Staff"**
3. **Fill in teacher details:**
   - Name: "Daniel Gyan"
   - Position: "Teacher"
   - Phone: "4535463465"
   - Specialization: "Science"
   - ☑️ **Check "Create login account"**
   - Email: "gyandaniel@gmail.com"
   - Password: "teacher123"
4. **Click "Add Staff Member"**

## ✅ **Expected Result**

- ✅ **Staff record created** in database
- ✅ **Login account created** in Supabase Auth
- ✅ **Teacher can login** immediately
- ✅ **No "User not allowed" error**

## 🔧 **How It Works**

### **Frontend (Registrar):**
1. Creates staff record in database
2. Calls `/api/create-staff-user` endpoint
3. Handles success/error responses

### **Backend API (`/api/create-staff-user`):**
1. Uses Supabase service role key (admin privileges)
2. Creates user in Supabase Auth
3. Links user ID to staff record
4. Creates users table entry
5. Returns success/error response

### **Security:**
- ✅ **Service role key** stays on server (secure)
- ✅ **Admin privileges** only on backend
- ✅ **Proper error handling** and cleanup
- ✅ **Validation** of required fields

## 🚨 **Important Notes**

1. **Service Role Key Security:**
   - Never expose this key in frontend code
   - Keep it in `.env` file only
   - Don't commit it to version control

2. **Error Handling:**
   - If login creation fails, staff record is still created
   - User gets clear error message
   - No partial states left in database

3. **User Roles:**
   - Teachers get `role: 'teacher'`
   - Other staff get `role: 'staff'`
   - Automatic role assignment based on position

## 🎯 **Benefits**

- ✅ **Complete teacher management** in Registrar
- ✅ **Secure user creation** via server API
- ✅ **No more "User not allowed" errors**
- ✅ **Proper error handling** and user feedback
- ✅ **Clean separation** of frontend/backend concerns

After setup, you'll be able to create teachers with login accounts directly from the Registrar interface!