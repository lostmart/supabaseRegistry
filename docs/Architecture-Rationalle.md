# Architecture

Supabase rest API

✅ Enables freemium (granular access control)
✅ Cost-effective (starts at $0, scales gracefully)
✅ Familiar stack (Node.js + Express is standard)
✅ GDPR-compliant (European data residency via Supabase)
✅ Fast to build (use existing JSON, migrate incrementally)
✅ Google and Apple Aouth
✅ Stripe payments
✅ Easy to use (REST API, no SDKs)

Deployment Timeline:

- Week 1: Set up Supabase schema + migrate questions
- Week 2: Build Node.js API (auth + questions endpoint)
- Week 3: Deploy to Render + integrate frontend
- Week 4: Add Stripe + premium content gates
- Week 5: Add study progress tracking
- Week 6: Add theme metadata
- Week 7: Add user preferences

                             ↓

  ┌──────────────────────────────────────────────────────────────┐
  │ Supabase (Database + Auth) │
  │ ┌──────────────────────────────────────────────────────────┐ │
  │ │ PostgreSQL Tables: │ │
  │ │ • auth.users (managed by Supabase) │ │
  │ │ • user_profiles (subscription_tier, preferences) │ │
  │ │ • questions (id, level, theme, text_fr, text_en, ...) │ │
  │ │ • study_progress (user_id, progress_data, last_synced) │ │
  │ └──────────────────────────────────────────────────────────┘ │
  └──────────────────────────────────────────────────────────────┘
