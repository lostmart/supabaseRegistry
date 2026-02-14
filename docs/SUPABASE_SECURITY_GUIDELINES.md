# Supabase Security & RLS Guidelines for Citoyenneté API

## Context

This document outlines critical security considerations for the Citoyenneté French civic exam preparation app. The app uses a freemium model where content access is controlled at the database level using Supabase Row Level Security (RLS).
IMPORTANT: Always refer to these guidelines when making database schema changes, writing queries, or handling authentication.

## 1. Row Level Security (RLS) - NON-NEGOTIABLE

Core Principle: Lock-by-Default

ALL tables MUST have RLS enabled
Once RLS is enabled, ALL access is denied by default
You must write explicit policies to allow operations
Missing policies = empty results or errors (this is intentional)

Example: Questions Table (Core Business Logic)

```sql
-- Enable RLS first
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Policy 1: Free users see non-premium questions
CREATE POLICY "free_users_see_free_content"
ON questions FOR SELECT
USING (
  is_premium = false
);

-- Policy 2: Premium users see ALL questions
CREATE POLICY "premium_users_see_all_content"
ON questions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid()
    AND subscription_tier IN ('premium', 'lifetime')
  )
);

-- Policy 3: Only backend can INSERT/UPDATE questions
-- (No client-side policy = denied by default)
```

## 2. Identity-Based Access Control - CRITICAL

The auth.uid() Pattern
ALWAYS use auth.uid() to restrict access to the current user's data.
User Profiles Table

```sql
-- Users can READ their own profile only
CREATE POLICY "users_read_own_profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Users CANNOT update their subscription tier
-- (Only backend with service key can do this via Stripe webhook)
CREATE POLICY "block_tier_updates_from_client"
ON user_profiles FOR UPDATE
USING (false);  -- Explicitly blocks ALL client updates
```

Study Progress Table (Premium Feature)

```sql
-- Users can only access their own progress
CREATE POLICY "users_own_progress_only"
ON study_progress FOR ALL
USING (auth.uid() = user_id);
```

⚠️ GDPR Violation Risk
If you forget auth.uid() = user_id, any authenticated user can access ANY other user's data.

## 3. API Key Hierarchy - SECURITY CRITICAL

- Frontend Configuration (Safe to Expose)

```javascript
// .env.local or Vite/Next.js public env
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...  // ✅ Safe in frontend code
```

- Backend Configuration (NEVER EXPOSE)

```javascript
// .env (must be in .gitignore)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGc...  // ⚠️ NEVER commit or expose
```

## 4. Database Schema Integrity

Adding Columns to Existing Tables

```sql
-- ❌ FAILS if table has existing data
ALTER TABLE questions
ADD COLUMN difficulty INTEGER NOT NULL;

-- ✅ Option 1: Provide default value
ALTER TABLE questions
ADD COLUMN difficulty INTEGER DEFAULT 3;

-- ✅ Option 2: Make it nullable
ALTER TABLE questions
ADD COLUMN difficulty INTEGER;
```

Primary Keys Are Required

```sql
-- ✅ Every table needs a primary key
CREATE TABLE questions (
  id TEXT PRIMARY KEY,  -- Required for .eq('id', value)
  -- ...
);

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  -- ...
);
```

## 5. Real-time Configuration (Future Feature)

- When Citoyenneté Needs Real-time

❌ Not needed for MVP (solo study app)
✅ Future: Collaborative study sessions
✅ Future: Live leaderboards
✅ Future: Admin dashboard

```javascript
// Frontend: Subscribe to changes
const subscription = supabase
	.channel("study-progress")
	.on(
		"postgres_changes",
		{ event: "*", schema: "public", table: "study_progress" },
		(payload) => console.log(payload),
	)
	.subscribe()

// ⚠️ CRITICAL: Always cleanup to prevent memory leaks
useEffect(() => {
	return () => {
		subscription.unsubscribe() // Required
	}
}, [])
```

## 6. File Storage Security (Phase 2 Feature)

When Needed

- User profile photos
- Document uploads (dossier builder)
- Audio files

### Storage Bucket RLS

```sql
-- Users can only upload to their own folder
CREATE POLICY "users_upload_own_files"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can only read their own files
CREATE POLICY "users_read_own_files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## 7. Testing RLS Policies

Local Testing Workflow

```bash
# 1. Start local Supabase
supabase start

# 2. Apply migrations
supabase db reset

# 3. Test with different users
```

Test Scenarios

Free User Test

Create test user with tier = 'free'
Query questions → Should only see is_premium = false
Try to access premium questions → Should get empty array

Premium User Test

Create test user with tier = 'premium'
Query questions → Should see ALL questions

Unauthorized Access Test

Try to update another user's profile → Should fail
Try to update own subscription_tier → Should fail

## 8. Common RLS Mistakes to Avoid

❌ Mistake 1: Forgetting to Enable RLS
sql-- Without this, table is wide open to anyone with anon key
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
❌ Mistake 2: Writing One Policy for All Operations
sql-- This only allows SELECT, not INSERT/UPDATE/DELETE
CREATE POLICY "all_access" ON questions
FOR SELECT USING (true);

-- You need separate policies for each operation
❌ Mistake 3: Not Using auth.uid()
sql-- ❌ Bad: Any authenticated user can see all profiles
CREATE POLICY "read_profiles" ON user_profiles
FOR SELECT USING (true);

-- ✅ Good: Users only see their own profile
CREATE POLICY "read_own_profile" ON user_profiles
FOR SELECT USING (auth.uid() = id);
❌ Mistake 4: Using Service Key in Frontend
typescript// ❌ NEVER do this - bypasses all security
const supabase = createClient(url, serviceKey)

// ✅ Frontend should use anon key
const supabase = createClient(url, anonKey)

```

---

## 9. Environment Variables Checklist

### .gitignore (REQUIRED)
```

.env
.env.local
.env.production
.env.development
node_modules/
dist/
Backend .env Structure
bash# Supabase (NEVER commit these)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGc...

# Server

PORT=3000
NODE_ENV=development

# CORS

ALLOWED_ORIGINS=http://localhost:5173,https://citoyennete.app
Frontend .env Structure
bash# Public variables (safe to expose)
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...

## 10. GDPR Compliance Requirements

Data Minimization

✅ Only store: user_id, subscription_tier, preferred_language
❌ Avoid storing: Full names, addresses, phone numbers (unless required)

Right to Erasure

```sql
-- Use CASCADE to auto-delete related data
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  -- ...
);

CREATE TABLE study_progress (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  -- ...
);
```

When to Consult This Document
✅ Always check this when:

Creating new tables
Writing database queries
Implementing authentication
Adding user-facing features
Deploying to production
Reviewing security before launch

## Debugging Checklist

```sql
-- 1. Is RLS enabled?
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- 2. What policies exist?
SELECT * FROM pg_policies
WHERE tablename = 'questions';

-- 3. Test as specific user
SET request.jwt.claims.sub = 'user-uuid';
SELECT * FROM questions;
```

**Last Updated:** February 13, 2025
**For:** Citoyenneté API Development
**Maintainer:** Mart
