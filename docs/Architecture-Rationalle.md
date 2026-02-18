# Architecture

Supabase rest API

✅ Enables freemium (granular access control)
✅ Cost-effective (starts at $0, scales gracefully)
✅ Familiar stack (Node.js + Express is standard)
✅ GDPR-compliant (European data residency via Supabase)
✅ Fast to build (use existing JSON, migrate incrementally)
✅ Google and Apple OAuth
✅ Stripe payments
✅ Easy to use (REST API, no SDKs)

Deployment Timeline:

- ✅ Week 1: Set up Supabase schema + migrate questions
- ✅ Week 2: Build Node.js API (auth + questions endpoint)
- ✅ Week 3: Deploy to Render + integrate frontend
- ✅ Week 4: Add Stripe + premium content gates (user_subscriptions)
- ✅ Week 5: Add study progress tracking (study_progress)
- ✅ Week 6: Add theme metadata (themes + subtopics)
- ✅ Week 7: Add user preferences (user_profiles)
- ✅ Week 8: Add quiz session tracking (quiz_sessions)

                             ↓

  ┌────────────────────────────────────────────────────────────────────────┐
  │ Supabase (Database + Auth)                                             │
  │ ┌──────────────────────────────────────────────────────────────────┐   │
  │ │ PostgreSQL Tables:                                               │   │
  │ │                                                                  │   │
  │ │ • auth.users (managed by Supabase)                               │   │
  │ │                                                                  │   │
  │ │ • themes (id, title, title_en, description, color_scheme)        │   │
  │ │ • subtopics (id, theme_id, title, subtitle, key_points, ...)     │   │
  │ │ • questions (id, theme_id, exam_type, question_type,             │   │
  │ │              question_text_fr, question_text_en, options,        │   │
  │ │              correct_answer, explanation_fr, explanation_en,     │   │
  │ │              source, tags, difficulty)                           │   │
  │ │                                                                  │   │
  │ │ • user_profiles (id → auth.users, preferred_language,           │   │
  │ │                  subscription_tier, target_exam_level)           │   │
  │ │ • user_subscriptions (id, user_id, stripe_subscription_id,      │   │
  │ │                       stripe_payment_intent_id, tier, status,   │   │
  │ │                       started_at, expires_at)                    │   │
  │ │                                                                  │   │
  │ │ • study_progress (id, user_id, question_id, attempts,           │   │
  │ │                   correct_attempts, last_answered_at,           │   │
  │ │                   confidence_level, last_self_rated_at)          │   │
  │ │                                                                  │   │
  │ │ • quiz_sessions (id, user_id, session_type, exam_level,         │   │
  │ │                  theme_id, total_questions, correct_answers,    │   │
  │ │                  score_percentage, is_passed,                   │   │
  │ │                  time_total_seconds, question_results,          │   │
  │ │                  started_at, completed_at, created_at)          │   │
  │ └──────────────────────────────────────────────────────────────────┘   │
  └────────────────────────────────────────────────────────────────────────┘
