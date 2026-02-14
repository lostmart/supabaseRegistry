What This Document Provides

1. Market-Driven Foundation

User research insights from your deep search (4 behavioral archetypes, pain points backed by real quotes)
Legislative context (January 2026 reforms, B1→B2 language requirement, 80% pass threshold)
Competitive analysis showing gaps in existing solutions

2. Complete Database Architecture

Full schema design with rationale for every table and column
Question ID naming convention (q_csp_pv_k_001 format)
Multilingual content strategy (French/English/Spanish columns, not JSON)
Spaced repetition support built into study_progress table

3. Security-First Implementation

Detailed RLS policies with test scripts
Freemium enforcement at database level (not application code)
GDPR compliance (CASCADE deletes, data minimization, EU residency)
Clear separation of anon key (frontend) vs service key (backend)

4. Content Strategy

The 5 official French civic exam themes mapped to database
28 published knowledge questions + 12 proprietary situational questions
Offline-first media strategy (Supabase Storage, no YouTube/SoundCloud)
Source verification workflow with source_verified_at timestamps

5. Practical Implementation Guides

Complete migration files (initial schema, RLS policies, triggers)
Seed data for local testing (includes test users with free/premium tiers)
API endpoint examples with authentication middleware
Stripe integration flow (checkout sessions, webhook handlers)

6. Production Deployment

Supabase CLI setup (local → production push)
Render.com backend deployment instructions
Netlify frontend deployment configuration
DNS setup on OVH

Key Technical Decisions Explained
Why Supabase (Not Firebase)?

Native PostgreSQL RLS for freemium (more granular than Firestore rules)
EU region selection for GDPR compliance
Familiar SQL vs NoSQL learning curve
Better offline PWA support

Why Separate user_profiles Table?

auth.users is managed by Supabase (can't add custom columns)
1:1 relationship with ON DELETE CASCADE for GDPR right to erasure
Automatic profile creation via database trigger

Why JSONB for Question Options?

Flexibility (2-option True/False vs 4-option multiple choice)
Multilingual support without complex joins
PostgreSQL JSONB is indexed and queryable

Why Text Columns for Translations (Not JSON)?

Easier querying: SELECT question_text_fr vs SELECT question_text->>'fr'
Better TypeScript type safety
Simpler API responses (no JSON parsing)
