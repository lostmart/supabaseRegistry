# Supabase Tables — Frontend Data Reference

> **Audience:** Frontend team
> **Purpose:** Data contracts, field types, constraints, and access rules to ensure consistency between frontend and backend.
> **Last updated:** 2026-02-25

---

## Table of Contents

1. [Auth & Identity](#1-auth--identity)
2. [Edge Functions](#2-edge-functions)
3. [Content Tables (Read-only)](#3-content-tables-read-only)
   - [themes](#31-themes)
   - [subtopics](#32-subtopics)
   - [questions](#33-questions)
4. [User Data Tables](#4-user-data-tables)
   - [user_profiles](#41-user_profiles)
   - [user_subscriptions](#42-user_subscriptions)
   - [study_progress](#43-study_progress)
   - [quiz_sessions](#44-quiz_sessions)
5. [Enums & Literals](#5-enums--literals)
6. [JSONB Schemas](#6-jsonb-schemas)
7. [Relationship Diagram](#7-relationship-diagram)
8. [RLS — What the Frontend Can Access](#8-rls--what-the-frontend-can-access)
9. [Key Invariants & Gotchas](#9-key-invariants--gotchas)

---

## 1. Auth & Identity

Authentication is handled by **Supabase Auth** (`auth.users`). The frontend never touches `auth.users` directly — it uses the Supabase client SDK.

**Supported auth methods:**
- Email + Password (signup confirmation is disabled — users can log in immediately)
- Google OAuth

**JWT expiry:** 1 hour — use `supabase.auth.onAuthStateChange` to handle token refresh.

When a new user signs up, a `user_profiles` row is **automatically created** via a database trigger. The frontend does not need to call an API to provision a profile.

---

## 2. Edge Functions

Custom server-side logic deployed on the Supabase Edge Runtime (Deno).

### `DELETE /functions/v1/delete-user`

Permanently deletes the authenticated user's account and **all associated data** in one call.

**Auth:** Required — pass the user's JWT as a Bearer token.

**Methods:** `POST` or `DELETE`

**Request — no body required:**
```ts
// Using the Supabase JS client (recommended)
const { error } = await supabase.functions.invoke('delete-user', {
  method: 'DELETE',
})

// Or with fetch directly
await fetch(`${SUPABASE_URL}/functions/v1/delete-user`, {
  method: 'DELETE',
  headers: { Authorization: `Bearer ${session.access_token}` },
})
```

**Success response `200`:**
```json
{ "message": "Account deleted successfully" }
```

**Error responses:**

| Status | Body | Cause |
|--------|------|-------|
| `401` | `{ "error": "Unauthorized" }` | Missing, expired, or invalid JWT |
| `405` | `{ "error": "Method not allowed" }` | Wrong HTTP method |
| `500` | `{ "error": "Failed to delete account" }` | Unexpected server error |

**What gets deleted (via `ON DELETE CASCADE`):**

| Table | Deletion mechanism |
|-------|--------------------|
| `user_profiles` | CASCADE from `auth.users` |
| `user_subscriptions` | CASCADE from `auth.users` |
| `study_progress` | CASCADE from `auth.users` |
| `quiz_sessions` | CASCADE from `auth.users` |

> After a successful call, the user's JWT is immediately invalidated. Sign the user out client-side and redirect them — any further authenticated request will return 401.

---

## 3. Content Tables (Read-only)

These tables are seeded/managed by the backend. The frontend **reads only**.

### 2.1 `themes`

The 5 official exam categories. Immutable — no inserts or updates by the frontend.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` | Primary key. One of: `pv`, `inst`, `dd`, `hist`, `vie` |
| `title` | `TEXT` | French label |
| `title_en` | `TEXT` | English label |
| `description` | `TEXT` | Nullable |
| `color_scheme` | `TEXT` | Nullable — UI theming hint |
| `created_at` | `TIMESTAMPTZ` | |

**Seeded rows:**

| id | title | title_en |
|----|-------|----------|
| `pv` | Principes et valeurs de la République | Principles and Values of the Republic |
| `inst` | Système institutionnel et politique | Institutional and Political System |
| `dd` | Droits et devoirs | Rights and Duties |
| `hist` | Histoire, géographie et culture | History, Geography and Culture |
| `vie` | Vivre dans la société française | Living in French Society |

**Access:** All authenticated users.

---

### 2.2 `subtopics`

Learning units nested within a theme (e.g., "Laïcité" inside `pv`).

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` | Primary key |
| `theme_id` | `TEXT` | FK → `themes.id` |
| `title` | `TEXT` | |
| `subtitle` | `TEXT` | Nullable |
| `description` | `TEXT` | Nullable |
| `key_points` | `JSONB` | Array of strings — bullet points for learning cards |
| `exam_tip` | `TEXT` | Nullable — strategic exam advice |
| `image` | `TEXT` | Nullable — asset identifier |
| `created_at` | `TIMESTAMPTZ` | |

**Access:** All authenticated users.

---

### 2.3 `questions`

MCQ exam questions. The core content of the app.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | `TEXT` | PK | Format: `q_{level}_{theme}_{type}_{nnn}` — e.g. `q_csp_pv_k_001` |
| `theme_id` | `TEXT` | FK → `themes.id` | |
| `exam_type` | `TEXT` | `'CSP' \| 'CR' \| 'NAT'` | Exam pathway level |
| `question_type` | `TEXT` | `'knowledge' \| 'situational'` | |
| `question_text_fr` | `TEXT` | NOT NULL | Always French (official exam language) |
| `question_text_en` | `TEXT` | Nullable | English translation |
| `options` | `JSONB` | NOT NULL | See [JSONB Schemas](#51-questionsoptions) |
| `correct_answer` | `TEXT` | NOT NULL | Label of correct option: `A`, `B`, `C`, or `D` |
| `explanation_fr` | `TEXT` | Nullable | Why the answer is correct |
| `explanation_en` | `TEXT` | Nullable | English explanation |
| `source` | `JSONB` | Nullable | See [JSONB Schemas](#52-questionssource) |
| `tags` | `TEXT[]` | Nullable | e.g. `['laicite', 'trap_question']` |
| `difficulty` | `INTEGER` | `1–5` | Within-level difficulty scale |
| `created_at` | `TIMESTAMPTZ` | | |

**ID format breakdown:**

```
q _ csp _ pv _ k _ 001
│   │     │   │   └── sequence number (3 digits)
│   │     │   └────── type: k = knowledge, s = situational
│   │     └────────── theme id
│   └──────────────── exam level
└──────────────────── prefix
```

**Access (freemium gate):**
- `exam_type = 'CSP'` → all authenticated users
- `exam_type IN ('CR', 'NAT')` → requires `user_profiles.subscription_tier IN ('premium', 'lifetime')`

**Exam structure for reference (full mock exam):**
- 40 questions total: 28 knowledge + 12 situational
- `pv` (Principes et valeurs) carries the heaviest weight (~11/40 questions)

---

## 3. User Data Tables

These tables contain per-user data. **All reads and writes are scoped to the authenticated user** via RLS — there is no risk of reading another user's data.

### 3.1 `user_profiles`

One row per user, auto-created on signup. The frontend can **read and update** the user's own row.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `id` | `UUID` | — | PK = `auth.uid()` |
| `preferred_language` | `TEXT` | `'fr'` | `'fr' \| 'en' \| 'es' \| 'ar'` |
| `subscription_tier` | `TEXT` | `'free'` | `'free' \| 'premium' \| 'lifetime'` |
| `target_exam_level` | `TEXT` | `NULL` | `'CSP' \| 'CR' \| 'NAT'` — user's immigration pathway goal |
| `created_at` | `TIMESTAMPTZ` | `NOW()` | |
| `updated_at` | `TIMESTAMPTZ` | `NOW()` | Auto-updated by DB trigger on every update |

**Frontend operations:**
- `SELECT` own row → allowed
- `UPDATE preferred_language`, `target_exam_level` → allowed
- `UPDATE subscription_tier` → **NOT allowed from frontend** — only updated by backend (Stripe webhook)

---

### 3.2 `user_subscriptions`

Stripe payment records. The frontend can **read only** — all writes are performed by the backend via service key.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `UUID` | PK |
| `user_id` | `UUID` | FK → `auth.users.id` |
| `stripe_subscription_id` | `TEXT` | Nullable (null for one-time lifetime payments) |
| `stripe_payment_intent_id` | `TEXT` | Nullable |
| `tier` | `subscription_tier_enum` | `'premium' \| 'lifetime'` |
| `status` | `subscription_status_enum` | `'active' \| 'cancelled' \| 'expired'` |
| `started_at` | `TIMESTAMPTZ` | |
| `expires_at` | `TIMESTAMPTZ` | **NULL for lifetime** — check for null before showing expiry date |
| `created_at` | `TIMESTAMPTZ` | |
| `updated_at` | `TIMESTAMPTZ` | Auto-updated by DB trigger |

**Frontend use cases:**
- Display subscription status and expiry
- Show upgrade prompts based on `status` and `expires_at`

---

### 3.3 `study_progress`

Per-question cumulative learning data. One row per `(user_id, question_id)` pair. This powers spaced repetition and mastery tracking.

| Column | Type | Default | Constraints | Notes |
|--------|------|---------|-------------|-------|
| `id` | `UUID` | `gen_random_uuid()` | PK | |
| `user_id` | `UUID` | — | FK → `auth.users.id` | |
| `question_id` | `TEXT` | — | FK → `questions.id` | |
| `attempts` | `INTEGER` | `0` | ≥ 0 | Total times answered |
| `correct_attempts` | `INTEGER` | `0` | ≤ `attempts` | Total correct answers |
| `last_answered_at` | `TIMESTAMPTZ` | `NULL` | | Updated after each answer |
| `confidence_level` | `INTEGER` | `NULL` | `1–5` | Self-rated in flashcard mode (1 = no idea, 5 = mastered) |
| `last_self_rated_at` | `TIMESTAMPTZ` | `NULL` | | Set when user rates a flashcard |
| `created_at` | `TIMESTAMPTZ` | `NOW()` | | |
| `updated_at` | `TIMESTAMPTZ` | `NOW()` | | Auto-updated by trigger |

**Unique constraint:** `(user_id, question_id)` — use `upsert` (INSERT … ON CONFLICT DO UPDATE).

**Frontend operations:**
- `SELECT` own rows → allowed
- `INSERT` new row → allowed
- `UPDATE` attempts, correct_attempts, confidence_level → allowed
- Use **upsert** to avoid duplicate key errors

---

### 3.4 `quiz_sessions`

Session-level tracking — one row per quiz or flashcard session. **Immutable once completed** (no UPDATE policy).

| Column | Type | Default | Constraints | Notes |
|--------|------|---------|-------------|-------|
| `id` | `UUID` | `gen_random_uuid()` | PK | |
| `user_id` | `UUID` | — | FK → `auth.users.id` | |
| `session_type` | `TEXT` | — | See below | |
| `exam_level` | `TEXT` | — | `'CSP' \| 'CR' \| 'NAT'` | |
| `theme_id` | `TEXT` | `NULL` | FK → `themes.id` | Only set when `session_type = 'theme_practice'` |
| `total_questions` | `INTEGER` | — | NOT NULL | |
| `correct_answers` | `INTEGER` | `0` | ≤ `total_questions` | |
| `score_percentage` | `DECIMAL(5,2)` | — | **GENERATED** | `(correct_answers / total_questions) * 100` — computed by DB, **do not send in INSERT** |
| `is_passed` | `BOOLEAN` | — | **GENERATED** | `score_percentage >= 80` — computed by DB, **do not send in INSERT** |
| `time_total_seconds` | `INTEGER` | `NULL` | | Total session duration |
| `question_results` | `JSONB` | `[]` | NOT NULL | Per-question detail — see [JSONB Schemas](#53-quiz_sessionsquestion_results) |
| `started_at` | `TIMESTAMPTZ` | `NOW()` | | |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | | Set when user finishes; null if abandoned |
| `created_at` | `TIMESTAMPTZ` | `NOW()` | | |

**`session_type` values:**

| Value | Description | `theme_id` | `total_questions` |
|-------|-------------|------------|-------------------|
| `practice` | Free-form mixed-theme practice | `NULL` | Variable |
| `mock_exam` | Full 40-question exam simulation (45 min timer) | `NULL` | `40` |
| `flashcard_review` | Flip-card confidence self-rating | `NULL` or specific | Variable |
| `theme_practice` | Practice filtered to one theme | **Required** | Variable |

**Frontend operations:**
- `SELECT` own rows → allowed
- `INSERT` new session → allowed
- `UPDATE` → **not allowed** — sessions are write-once

> **Important:** Do **not** include `score_percentage` or `is_passed` in your INSERT payload — they are generated columns computed by the database automatically.

---

## 4. Enums & Literals

The following string literals are used as type constraints. Always use these exact values.

| Field | Allowed values |
|-------|---------------|
| `questions.exam_type` | `'CSP'`, `'CR'`, `'NAT'` |
| `questions.question_type` | `'knowledge'`, `'situational'` |
| `user_profiles.preferred_language` | `'fr'`, `'en'`, `'es'`, `'ar'` |
| `user_profiles.subscription_tier` | `'free'`, `'premium'`, `'lifetime'` |
| `user_profiles.target_exam_level` | `'CSP'`, `'CR'`, `'NAT'` (nullable) |
| `user_subscriptions.tier` | `'premium'`, `'lifetime'` |
| `user_subscriptions.status` | `'active'`, `'cancelled'`, `'expired'` |
| `quiz_sessions.session_type` | `'practice'`, `'mock_exam'`, `'flashcard_review'`, `'theme_practice'` |
| `quiz_sessions.exam_level` | `'CSP'`, `'CR'`, `'NAT'` |
| `study_progress.confidence_level` | `1`, `2`, `3`, `4`, `5` (nullable) |
| `questions.difficulty` | `1`, `2`, `3`, `4`, `5` |

---

## 5. JSONB Schemas

### 5.1 `questions.options`

Array of answer choices. Always 4 items (A, B, C, D).

```ts
type Option = {
  label: string;       // "A" | "B" | "C" | "D"
  text_fr: string;     // French answer text (always present)
  text_en?: string;    // English translation (may be absent)
};

type Options = Option[];  // length = 4
```

**Example:**
```json
[
  { "label": "A", "text_fr": "La devise de la République", "text_en": "The Republic's motto" },
  { "label": "B", "text_fr": "Le drapeau tricolore", "text_en": "The tricolor flag" },
  { "label": "C", "text_fr": "La Marseillaise", "text_en": "La Marseillaise" },
  { "label": "D", "text_fr": "La Constitution de 1958", "text_en": "The 1958 Constitution" }
]
```

`correct_answer` contains the `label` value of the correct option (e.g. `"B"`).

---

### 5.2 `questions.source`

Audit trail for question sourcing. Nullable at the question level.

```ts
type Source = {
  url?: string;
  name?: string;
  verified_date?: string;  // ISO date string
} | null;
```

---

### 5.3 `quiz_sessions.question_results`

Two different shapes depending on `session_type`.

**Quiz mode** (`practice`, `mock_exam`, `theme_practice`):
```ts
type QuizResult = {
  question_id: string;       // e.g. "q_csp_pv_k_001"
  selected_answer: string;   // "A" | "B" | "C" | "D"
  is_correct: boolean;
  time_seconds: number;
};
```

**Flashcard mode** (`flashcard_review`):
```ts
type FlashcardResult = {
  question_id: string;
  self_rated_confidence: number;  // 1–5
  time_seconds: number;
};
```

**Example INSERT payload (quiz session):**
```json
{
  "user_id": "uuid-...",
  "session_type": "mock_exam",
  "exam_level": "CSP",
  "total_questions": 40,
  "correct_answers": 34,
  "time_total_seconds": 2580,
  "completed_at": "2026-02-25T14:32:00Z",
  "question_results": [
    { "question_id": "q_csp_pv_k_001", "selected_answer": "B", "is_correct": true, "time_seconds": 34 },
    { "question_id": "q_csp_dd_k_003", "selected_answer": "A", "is_correct": false, "time_seconds": 52 }
  ]
}
```

> Note: omit `score_percentage` and `is_passed` — the DB computes them automatically.

---

## 6. Relationship Diagram

```
auth.users (Supabase Auth — managed by SDK)
  │
  ├─── user_profiles          (1:1) — auto-created on signup
  │
  ├─── user_subscriptions     (1:many) — Stripe payments, backend-managed
  │
  ├─── study_progress         (1:many) — per question, upserted by frontend
  │         └── question_id ──────────────── questions.id
  │
  └─── quiz_sessions          (1:many) — per session, insert-only
            └── theme_id ──────────────────── themes.id (nullable)

themes
  ├─── subtopics              (1:many)
  └─── questions              (1:many)
```

---

## 7. RLS — What the Frontend Can Access

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `themes` | ✅ all authenticated | ❌ | ❌ | ❌ |
| `subtopics` | ✅ all authenticated | ❌ | ❌ | ❌ |
| `questions` | ✅ CSP: all auth / CR+NAT: premium only | ❌ | ❌ | ❌ |
| `user_profiles` | ✅ own row only | ❌ (trigger) | ✅ own row only | ❌ |
| `user_subscriptions` | ✅ own rows only | ❌ (backend) | ❌ (backend) | ❌ |
| `study_progress` | ✅ own rows only | ✅ own rows only | ✅ own rows only | ❌ |
| `quiz_sessions` | ✅ own rows only | ✅ own rows only | ❌ (immutable) | ❌ |

---

## 8. Key Invariants & Gotchas

1. **Never send `score_percentage` or `is_passed` in a `quiz_sessions` INSERT** — they are generated columns. The DB will error if you include them.

2. **Use upsert for `study_progress`** — the unique constraint on `(user_id, question_id)` will cause a conflict on a plain INSERT if the row already exists:
   ```ts
   supabase.from('study_progress').upsert({ ... }, { onConflict: 'user_id,question_id' })
   ```

3. **`quiz_sessions` is insert-only** — there is no UPDATE RLS policy. If you need to track an in-progress session, either keep state client-side until completion or design your session flow to only write to the DB when the user finishes.

4. **`user_profiles.subscription_tier` is backend-managed** — do not attempt to update it from the frontend. Use `user_subscriptions.status` + `expires_at` to derive upgrade prompts, and rely on the DB value of `subscription_tier` for access control.

5. **`expires_at` is NULL for lifetime subscriptions** — always null-check before displaying an expiry date.

6. **Theme practice requires `theme_id`** — when creating a `quiz_sessions` row with `session_type = 'theme_practice'`, `theme_id` is required. The DB enforces this with a CHECK constraint.

7. **`study_progress.correct_attempts <= attempts`** — the DB enforces this invariant. Increment both counters together on a correct answer, only `attempts` on a wrong answer.

8. **Question access is enforced at the DB level** — even if the frontend hides premium content, the RLS policy on `questions` will block the query for free-tier users. Design your UI accordingly but do not rely solely on frontend gating.

9. **Language fallback** — `question_text_en`, `explanation_en`, and `options[].text_en` can be null. Always fall back to the `_fr` fields when the English translation is absent.
