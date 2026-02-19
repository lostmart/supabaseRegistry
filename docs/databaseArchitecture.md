# Citoyenneté — Database Architecture & Dashboard Data Model

> **Purpose**: This document is the single source of truth for all database schema decisions for the Citoyenneté French civic exam preparation app. Feed this to any Claude agent working on the backend, frontend dashboard, or API layer so it stays aligned with agreed architecture.
>
> **Last Updated**: February 18, 2026
> **Status**: All decisions confirmed. Migrations applied and running locally.

---

## 1. Product Context (Why This Schema Exists)

Citoyenneté is a PWA targeting 100,000+ annual French citizenship seekers and residence permit applicants affected by the January 2026 immigration reforms. The civic exam is a 40-question MCQ with an 80% pass threshold (32/40), covering 5 official themes at 3 difficulty levels (CSP, CR, NAT).

**Key user needs driving data model decisions:**

- Exam anxiety → users need to see mock exam score improvement over time
- 80% threshold pressure → users can't afford weak themes, need per-module progress
- Cost sensitivity (€70/attempt) → realistic mock exams reduce real exam failures
- Mobile-first commute study → session tracking must handle short, interrupted sessions
- Spaced repetition → per-question confidence tracking for intelligent review scheduling

**Freemium model:**

- Free tier: CSP-level questions only
- Premium tier: CR + NAT questions, full mock exams
- Enforced at database level via RLS policies (not application code)

---

## 2. Existing Schema (Already Implemented)

These tables exist in Supabase with migrations applied and RLS enabled.

### 2.1 `themes`

Stores the 5 official exam categories as educational content containers.

| Column         | Type        | Notes                                   |
| -------------- | ----------- | --------------------------------------- |
| `id`           | TEXT PK     | e.g., `pv`, `inst`, `dd`, `hist`, `vie` |
| `title`        | TEXT        | French title                            |
| `title_en`     | TEXT        | English title                           |
| `description`  | TEXT        |                                         |
| `color_scheme` | TEXT        | For UI theming                          |
| `created_at`   | TIMESTAMPTZ |                                         |

**The 5 themes:**

1. `pv` — Principes et valeurs de la République
2. `inst` — Système institutionnel et politique
3. `dd` — Droits et devoirs
4. `hist` — Histoire, géographie et culture
5. `vie` — Vivre dans la société française

### 2.2 `subtopics`

Learning units within each theme (e.g., "Laïcité" within Principes et Valeurs).

| Column        | Type             | Notes                  |
| ------------- | ---------------- | ---------------------- |
| `id`          | TEXT PK          |                        |
| `theme_id`    | TEXT FK → themes |                        |
| `title`       | TEXT             |                        |
| `subtitle`    | TEXT             |                        |
| `description` | TEXT             |                        |
| `key_points`  | JSONB            | Array of bullet points |
| `exam_tip`    | TEXT             | Strategic advice       |
| `image`       | TEXT             | Asset identifier       |
| `created_at`  | TIMESTAMPTZ      |                        |

### 2.3 `questions`

The MCQ exam questions. Human-readable IDs encode level, theme, type, and number.

| Column             | Type             | Notes                                                 |
| ------------------ | ---------------- | ----------------------------------------------------- |
| `id`               | TEXT PK          | Format: `q_{level}_{theme}_{type}_{number}`           |
| `theme_id`         | TEXT FK → themes |                                                       |
| `exam_type`        | TEXT             | `'CSP'`, `'CR'`, `'NAT'` (immigration pathway level)  |
| `question_type`    | TEXT             | `'knowledge'` or `'situational'`                      |
| `question_text_fr` | TEXT             | Always in French (exam language)                      |
| `question_text_en` | TEXT             | English translation                                   |
| `options`          | JSONB            | Array of answer objects `{ label, text_fr, text_en }` |
| `correct_answer`   | TEXT             | Label of correct option                               |
| `explanation_fr`   | TEXT             | Why the answer is correct                             |
| `explanation_en`   | TEXT             |                                                       |
| `source`           | JSONB            | `{ url, name, verified_date }` for audit trail        |
| `tags`             | TEXT[]           | e.g., `['trap_question', 'laicite', '1905_law']`      |
| `difficulty`       | INTEGER          | 1-5 within-level difficulty                           |
| `created_at`       | TIMESTAMPTZ      |                                                       |

**Question ID examples:**

- `q_csp_pv_k_001` → CSP, Principes et Valeurs, Knowledge, #1
- `q_cr_inst_s_012` → CR, Institutional System, Situational, #12
- `q_nat_hist_k_028` → NAT, History/Geography, Knowledge, #28

**Exam structure the questions map to:**

- 40 total questions per exam: 28 knowledge + 12 situational
- "Principes et valeurs" is the most heavily weighted (~11/40 questions)
- The 12 situational questions are unpublished by the Ministry — these are premium IP content

### 2.4 `study_progress`

Cumulative per-question tracking. One row per user+question pair. This is the spaced repetition backbone.

| Column             | Type                 | Notes                                                   |
| ------------------ | -------------------- | ------------------------------------------------------- |
| `id`               | UUID PK              |                                                         |
| `user_id`          | UUID FK → auth.users | ON DELETE CASCADE (GDPR)                                |
| `question_id`      | TEXT FK → questions  | ON DELETE CASCADE                                       |
| `attempts`         | INTEGER              | Total times answered (across all sessions)              |
| `correct_attempts` | INTEGER              | Total times answered correctly                          |
| `last_answered_at` | TIMESTAMPTZ          | Last interaction timestamp                              |
| `confidence_level` | INTEGER (1-5)        | Spaced repetition rating. 1 = "No idea", 5 = "Mastered" |
| `created_at`       | TIMESTAMPTZ          |                                                         |
| `updated_at`       | TIMESTAMPTZ          |                                                         |

**Constraints:** `UNIQUE(user_id, question_id)`
**Index:** `idx_study_progress_user_confidence ON (user_id, confidence_level)`

### 2.5 `user_profiles`

Separate from Supabase `auth.users` to store app-specific user data.

| Column               | Type        | Notes                                              |
| -------------------- | ----------- | -------------------------------------------------- |
| `id`                 | UUID PK     | FK → auth.users ON DELETE CASCADE                  |
| `preferred_language` | TEXT        | `'fr'`, `'en'`, `'es'`, `'ar'`                     |
| `subscription_tier`  | TEXT        | `'free'`, `'premium'`, `'lifetime'`                |
| `target_exam_level`  | TEXT        | `'CSP'`, `'CR'`, `'NAT'` — user's immigration goal |
| `created_at`         | TIMESTAMPTZ |                                                    |
| `updated_at`         | TIMESTAMPTZ |                                                    |

### 2.6 `user_subscriptions`

Stripe payment tracking for premium access.

| Column                     | Type                 | Notes                                  |
| -------------------------- | -------------------- | -------------------------------------- |
| `id`                       | UUID PK              |                                        |
| `user_id`                  | UUID FK → auth.users | ON DELETE CASCADE                      |
| `stripe_subscription_id`   | TEXT                 | Nullable for one-time payments         |
| `stripe_payment_intent_id` | TEXT                 |                                        |
| `tier`                     | ENUM                 | `'premium'`, `'lifetime'`              |
| `status`                   | ENUM                 | `'active'`, `'cancelled'`, `'expired'` |
| `started_at`               | TIMESTAMPTZ          |                                        |
| `expires_at`               | TIMESTAMPTZ          |                                        |
| `created_at`               | TIMESTAMPTZ          |                                        |
| `updated_at`               | TIMESTAMPTZ          |                                        |

---

## 3. New Table: `quiz_sessions` (To Be Implemented)

This table fills the critical gap between per-question tracking (`study_progress`) and session-level dashboard metrics. Without it, we cannot show quiz history, score trends, or time spent.

### 3.1 Why It's Needed

`study_progress` is cumulative — it tells you "you've attempted this question 5 times and got it right 3 times." But it cannot tell you "you took a mock exam on Feb 15 and scored 85% in 32 minutes." The dashboard needs both views.

### 3.2 Table Structure

| Column               | Type                 | Notes                                                                                        |
| -------------------- | -------------------- | -------------------------------------------------------------------------------------------- |
| `id`                 | UUID PK              | `DEFAULT gen_random_uuid()`                                                                  |
| `user_id`            | UUID FK → auth.users | ON DELETE CASCADE (GDPR)                                                                     |
| `session_type`       | TEXT                 | `'practice'`, `'mock_exam'`, `'flashcard_review'`, `'theme_practice'`                        |
| `exam_level`         | TEXT                 | `'CSP'`, `'CR'`, `'NAT'` — which pathway this session targeted                               |
| `theme_id`           | TEXT FK → themes     | Nullable — only for `theme_practice` sessions                                                |
| `total_questions`    | INTEGER              | Number of questions in this session                                                          |
| `correct_answers`    | INTEGER              | Number answered correctly                                                                    |
| `score_percentage`   | DECIMAL(5,2)         | `GENERATED ALWAYS AS` computed from correct_answers/total_questions. Cannot be manually set. |
| `is_passed`          | BOOLEAN              | `GENERATED ALWAYS AS` true when score >= 80%. Cannot be manually set.                        |
| `time_total_seconds` | INTEGER              | Total session duration                                                                       |
| `question_results`   | JSONB                | Per-question detail array (see §3.3)                                                         |
| `started_at`         | TIMESTAMPTZ          | When user began the session                                                                  |
| `completed_at`       | TIMESTAMPTZ          | When user finished (null if abandoned)                                                       |
| `created_at`         | TIMESTAMPTZ          | `DEFAULT NOW()`                                                                              |

### 3.3 `question_results` JSONB Structure

Each session stores an array of per-question results. This enables per-question time tracking without a separate join table.

```json
[
	{
		"question_id": "q_csp_pv_k_001",
		"selected_answer": "b",
		"is_correct": true,
		"time_seconds": 34
	},
	{
		"question_id": "q_csp_pv_k_002",
		"selected_answer": "a",
		"is_correct": false,
		"time_seconds": 89
	}
]
```

**Why JSONB instead of a separate `quiz_session_answers` table:**

- A session has at most 40 questions — the array is always small
- Reduces table count and join complexity
- Single INSERT per completed session (better write performance)
- PostgreSQL JSONB operators allow querying into the array if needed later
- Per-user analytics are the primary use case (not cross-user aggregation on individual answers)

**Trade-off accepted:** Cross-user analytics on specific questions (e.g., "what's the average time all users spend on question X?") requires JSONB extraction rather than a simple SQL aggregate. This is acceptable for MVP. If cross-user analytics become a priority, consider migrating to a normalized `quiz_session_answers` table.

### 3.4 Flashcard Sessions

Flashcards are **not separate content** — they present the same `questions` table entries in a flip-card format. The difference is interaction mode:

- **Quiz mode**: User selects an answer → system scores it → updates `study_progress.attempts` and `correct_attempts`
- **Flashcard mode**: User sees question, mentally answers, flips card, then **self-rates confidence** → updates `study_progress.confidence_level`

A flashcard session is stored as a `quiz_sessions` row with `session_type = 'flashcard_review'`. The `question_results` JSONB adapts slightly:

```json
[
	{
		"question_id": "q_csp_pv_k_001",
		"self_rated_confidence": 4,
		"time_seconds": 12
	},
	{
		"question_id": "q_csp_dd_k_005",
		"self_rated_confidence": 2,
		"time_seconds": 28
	}
]
```

Note: `selected_answer` and `is_correct` are absent (no objective scoring in flashcard mode). `self_rated_confidence` (1-5) maps directly to the spaced repetition scale.

### 3.5 Session Types Explained

| `session_type`     | Description                             | `theme_id`       | `exam_level`        | `total_questions` |
| ------------------ | --------------------------------------- | ---------------- | ------------------- | ----------------- |
| `practice`         | Free-form practice, mixed themes        | NULL             | User's target level | Variable          |
| `mock_exam`        | Full exam simulation (40q, 45min timer) | NULL             | Specific level      | 40                |
| `flashcard_review` | Flip-card confidence self-rating        | NULL or specific | User's target level | Variable          |
| `theme_practice`   | Practice filtered to one theme          | Required         | User's target level | Variable          |

### 3.6 Proposed Indexes

```sql
-- Dashboard: recent activity, quiz history
CREATE INDEX idx_quiz_sessions_user_completed
  ON quiz_sessions (user_id, completed_at DESC);

-- Dashboard: filter by session type
CREATE INDEX idx_quiz_sessions_user_type
  ON quiz_sessions (user_id, session_type);

-- Analytics: mock exam score trends
CREATE INDEX idx_quiz_sessions_mock_scores
  ON quiz_sessions (user_id, completed_at DESC)
  WHERE session_type = 'mock_exam';
```

### 3.7 RLS Policies Required

```sql
-- Users can only see their own sessions
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own sessions"
  ON quiz_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own sessions"
  ON quiz_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- No UPDATE policy: sessions are immutable once completed
-- No DELETE policy for users: only CASCADE from auth.users deletion (GDPR)
```

---

## 4. Modification to Existing `study_progress`

Add one column to distinguish flashcard self-ratings from algorithm-set confidence:

| New Column           | Type        | Notes                                                                                                          |
| -------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- |
| `last_self_rated_at` | TIMESTAMPTZ | Nullable. Updated when user rates confidence in flashcard mode. Helps readiness algorithm weight data sources. |

**Migration:**

```sql
ALTER TABLE study_progress
ADD COLUMN last_self_rated_at TIMESTAMPTZ;
```

---

## 5. Dashboard Widget → Data Source Mapping

This is the contract between backend API and frontend dashboard.

### 5.1 Widget: Quizzes Completed

```sql
SELECT COUNT(*) AS quizzes_completed
FROM quiz_sessions
WHERE user_id = :user_id
  AND session_type IN ('practice', 'mock_exam', 'theme_practice')
  AND completed_at IS NOT NULL;
```

### 5.2 Widget: Average Score

```sql
SELECT ROUND(AVG(score_percentage), 1) AS average_score
FROM quiz_sessions
WHERE user_id = :user_id
  AND session_type IN ('practice', 'mock_exam', 'theme_practice')
  AND completed_at IS NOT NULL;
```

### 5.3 Widget: Total Time

```sql
SELECT SUM(time_total_seconds) AS total_seconds
FROM quiz_sessions
WHERE user_id = :user_id
  AND completed_at IS NOT NULL;
```

Frontend formats as hours/minutes.

### 5.4 Widget: Flashcards Seen

```sql
-- Count UNIQUE questions encountered in flashcard mode
SELECT COUNT(DISTINCT elem->>'question_id') AS unique_flashcards_seen
FROM quiz_sessions,
     jsonb_array_elements(question_results) AS elem
WHERE user_id = :user_id
  AND session_type = 'flashcard_review';
```

### 5.5 Widget: Progress by Module

```sql
SELECT
  t.id AS theme_id,
  t.title AS theme_name,
  COUNT(DISTINCT sp.question_id) AS questions_attempted,
  total_q.total AS questions_available,
  ROUND(
    AVG(sp.correct_attempts::float / NULLIF(sp.attempts, 0)) * 100, 1
  ) AS accuracy_percentage,
  ROUND(AVG(sp.confidence_level), 1) AS avg_confidence
FROM study_progress sp
JOIN questions q ON sp.question_id = q.id
JOIN themes t ON q.theme_id = t.id
LEFT JOIN (
  SELECT theme_id, COUNT(*) AS total
  FROM questions
  WHERE exam_type = :user_target_level  -- CSP, CR, or NAT
  GROUP BY theme_id
) total_q ON t.id = total_q.theme_id
WHERE sp.user_id = :user_id
GROUP BY t.id, t.title, total_q.total
ORDER BY t.id;
```

**Note:** The dashboard shows 4 modules (Values and principles, Rights and duties, History/geography & culture, French society). The 5th theme "Système institutionnel et politique" is either shown as a 5th module or merged — confirm with frontend design. The query returns all 5 themes regardless.

### 5.6 Widget: Recent Activity

```sql
SELECT
  id,
  session_type,
  exam_level,
  total_questions,
  correct_answers,
  score_percentage,
  is_passed,
  time_total_seconds,
  completed_at
FROM quiz_sessions
WHERE user_id = :user_id
  AND completed_at IS NOT NULL
ORDER BY completed_at DESC
LIMIT 10;
```

### 5.7 Widget: Overall Readiness (Computed)

See §6 for the full algorithm.

---

## 6. Overall Readiness Score Algorithm

Computed on-the-fly (not stored). Returns a value 0–100 representing estimated exam readiness.

### 6.1 Components

| Component      | Weight | What It Measures                                    | Source                                           |
| -------------- | ------ | --------------------------------------------------- | ------------------------------------------------ |
| **Coverage**   | 25%    | % of questions user has seen, at their target level | `study_progress` vs `questions` count            |
| **Accuracy**   | 30%    | Rolling average of recent quiz session scores       | `quiz_sessions` (last 10 scored sessions)        |
| **Confidence** | 20%    | Distribution of spaced repetition confidence levels | `study_progress.confidence_level`                |
| **Mock Trend** | 25%    | Are full mock exam scores improving?                | `quiz_sessions WHERE session_type = 'mock_exam'` |

### 6.2 Pseudocode

```
function computeReadiness(user_id, target_level):

  // COVERAGE (0-100): What % of questions at user's level have they seen?
  total_questions = COUNT questions WHERE exam_type = target_level
  seen_questions = COUNT study_progress WHERE user_id AND question.exam_type = target_level
  coverage_score = (seen_questions / total_questions) * 100

  // ACCURACY (0-100): Average of last 10 scored sessions
  recent_scores = SELECT score_percentage FROM quiz_sessions
    WHERE user_id AND session_type IN ('practice', 'mock_exam', 'theme_practice')
    ORDER BY completed_at DESC LIMIT 10
  accuracy_score = AVG(recent_scores) OR 0 if none

  // CONFIDENCE (0-100): Map 1-5 scale to 0-100
  avg_confidence = AVG(confidence_level) FROM study_progress WHERE user_id
  confidence_score = (avg_confidence / 5) * 100 OR 0 if none

  // MOCK TREND (0-100): Compare last 3 mock exams
  mock_scores = SELECT score_percentage FROM quiz_sessions
    WHERE user_id AND session_type = 'mock_exam'
    ORDER BY completed_at DESC LIMIT 3

  IF fewer than 2 mocks:
    mock_trend_score = 0  // Not enough data
  ELSE:
    // Reward improvement: if scores are rising, boost; if falling, penalize
    latest = mock_scores[0]
    trend = latest - AVG(mock_scores[1:])
    mock_trend_score = CLAMP(latest + (trend * 2), 0, 100)

  // WEIGHTED TOTAL
  readiness = (coverage_score * 0.25)
            + (accuracy_score * 0.30)
            + (confidence_score * 0.20)
            + (mock_trend_score * 0.25)

  RETURN ROUND(readiness, 0)
```

### 6.3 Edge Cases

- **New user (no data):** Readiness = 0. Dashboard shows "Start your first quiz to track readiness."
- **Only flashcards, no quizzes:** Coverage and confidence have data; accuracy and mock trend are 0. Readiness will be low, which is correct — flashcards alone don't prove exam readiness.
- **User hasn't taken mock exams:** Mock trend = 0. Readiness capped around 75% max, nudging user to try a full mock.

### 6.4 Readiness Thresholds for UI

| Score Range | Label               | Color       | Message                                                     |
| ----------- | ------------------- | ----------- | ----------------------------------------------------------- |
| 0–25        | Getting Started     | Red         | "Keep practicing! Focus on learning the material."          |
| 26–50       | Building Foundation | Orange      | "Good progress. Try theme-specific practice on weak areas." |
| 51–75       | On Track            | Yellow      | "You're improving! Take a full mock exam to test yourself." |
| 76–89       | Almost Ready        | Light Green | "Strong performance. Fine-tune your weak themes."           |
| 90–100      | Exam Ready          | Green       | "You're ready! Consider booking your exam."                 |

---

## 7. Confirmed Decisions (All Resolved)

All open questions have been resolved. Migrations are applied and running.

### 7.1 Per-Question Answer Storage — ✅ JSONB

JSONB array in `quiz_sessions.question_results`. Implemented in migration `20260218000007`.

### 7.2 Session Types — ✅ Four Types Confirmed

`practice`, `mock_exam`, `flashcard_review`, `theme_practice`. Enforced via CHECK constraint.

### 7.3 Flashcards Seen Metric — ✅ Unique Questions

Dashboard shows **unique questions** seen via flashcard mode (COUNT DISTINCT on question_id).

### 7.4 Session Lifecycle — ✅ INSERT Only on Completion

Sessions are only written to the database when fully completed. No partial/in-progress rows.

- No UPDATE policy exists on `quiz_sessions` (sessions are immutable).
- In-progress state lives client-side (frontend memory).
- If user closes the app mid-quiz, that session is lost (acceptable trade-off for schema simplicity).
- Future enhancement: client-side persistence (IndexedDB) can buffer completed sessions for offline retry — this is a frontend concern, not a database change.

### 7.5 Generated Columns — ✅ Database-Enforced Thresholds

`score_percentage` and `is_passed` are `GENERATED ALWAYS AS ... STORED` columns on `quiz_sessions`. The 80% pass threshold is enforced by PostgreSQL, not application code. These columns cannot be manually set or overridden.

### 7.6 Migration Status

All 7 migrations applied successfully:

```
20260218000001_create_themes.sql
20260218000002_create_subtopics.sql
20260218000003_create_questions.sql
20260218000004_create_user_profiles.sql
20260218000005_create_user_subscriptions.sql
20260218000006_create_study_progress.sql
20260218000007_create_quiz_sessions.sql
```

---

## 8. Complete Entity Relationship Summary

```
auth.users (Supabase managed)
  │
  ├── user_profiles (1:1)
  │     └── subscription_tier, preferred_language, target_exam_level
  │
  ├── user_subscriptions (1:many)
  │     └── Stripe payment records
  │
  ├── study_progress (1:many, UNIQUE per user+question)
  │     └── Cumulative per-question stats + spaced repetition confidence
  │     └── FK → questions
  │
  └── quiz_sessions (1:many)  ← NEW
        └── Session-level stats + JSONB per-question detail
        └── FK → themes (nullable, for theme_practice only)

themes (5 rows)
  │
  ├── subtopics (1:many)
  │     └── Educational content units
  │
  └── questions (1:many)
        └── MCQ content with level/type/difficulty
        └── Referenced by study_progress.question_id
        └── Referenced inside quiz_sessions.question_results JSONB
```

---

## 9. GDPR & Security Invariants

These rules apply to ALL tables containing user data:

1. **ON DELETE CASCADE** from `auth.users` on every FK. When a user deletes their account, ALL their data is automatically purged.
2. **RLS enabled** on every table. No table should ever be UNRESTRICTED.
3. **Identity-based policies**: Users can only read/write their own data (`auth.uid() = user_id`).
4. **Quiz sessions are immutable**: No UPDATE policy. Once a session is completed, it cannot be modified. This ensures analytics integrity.
5. **Service key for admin only**: Cross-user analytics queries (e.g., "hardest questions globally") run via backend using the service key, never from the frontend.
6. **Data minimization**: No full names, addresses, or phone numbers stored. Only: user_id, language preference, subscription tier, target exam level, and learning interaction data.
7. **EU data residency**: Supabase project must be in EU region (Frankfurt or Paris).

---

## 10. Implementation Checklist

### Database (Complete)

- [x] Confirm the 3 open questions in §7
- [x] Create migration: themes, subtopics, questions, user_profiles, user_subscriptions, study_progress, quiz_sessions
- [x] Add `quiz_sessions` table with generated columns, constraints, and indexes
- [x] Add `last_self_rated_at` column to `study_progress`
- [x] Enable RLS on all tables with identity-based policies
- [x] Run `supabase db reset` — all 7 migrations applied
- [ ] Verify in Supabase Studio: confirm French characters display correctly in `themes` seed data
- [ ] Create `seed.sql` with test questions for development

### API Endpoints (Next)

- [ ] `POST /api/sessions` — create a completed quiz session (INSERT only, no partial sessions)
- [ ] `GET /api/sessions` — list user's sessions (paginated, filtered by type)
- [ ] `GET /api/dashboard` — aggregated dashboard stats (all widgets from §5)
- [ ] `GET /api/readiness` — computed readiness score (algorithm from §6)

### Integration Logic (Next)

- [ ] Upsert logic for `study_progress` handling both quiz answers and flashcard self-ratings
- [ ] Test RLS: confirm users cannot see other users' sessions or progress
- [ ] Test CASCADE: confirm deleting a user removes all sessions, progress, profile, and subscriptions
- [ ] Import full question content from JSON files into `questions` table

```

```

## 11. QCM 20 questions practice

All 20 rows confirmed. Here's a summary of what was created:

File: supabase/migrations/20260219000001_seed_qcm_fr.sql

The migration inserts all 20 questions into the existing questions table with proper mapping:

┌────────────────┬───────────────────────────────────────────────────────────────┐
│ Field │ Mapping │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ id │ q*csp*{theme}_{k|s}_{nnn} │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ theme_id │ category → dd, inst, vie, hist, pv │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ exam_type │ CSP (all users can access) │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ question_type │ situational for "Mise en situation", knowledge for all others │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ options │ JSONB array with labels A/B/C/D + text_fr │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ correct_answer │ Label string ("A", "B", "C", "D") │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ explanation_fr │ Cleaned explanation text │
├────────────────┼───────────────────────────────────────────────────────────────┤
│ difficulty │ 1 (easy), 2 (medium), 3 (situational/harder) │
└────────────────┴───────────────────────────────────────────────────────────────┘

Theme distribution:

- dd (Droits et devoirs): 8 questions (5 knowledge + 3 situational)
- inst (Système institutionnel): 4 questions
- vie (Vie en société): 5 questions
- hist (Histoire/géographie): 5 questions
