-- Migration: create_quiz_sessions
-- Session-level tracking. Fills the gap between per-question study_progress
-- and dashboard metrics (quiz history, score trends, time spent).

CREATE TABLE quiz_sessions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_type         TEXT NOT NULL CHECK (session_type IN ('practice', 'mock_exam', 'flashcard_review', 'theme_practice')),
  exam_level           TEXT NOT NULL CHECK (exam_level IN ('CSP', 'CR', 'NAT')),
  theme_id             TEXT REFERENCES themes(id) ON DELETE SET NULL,  -- Only for theme_practice
  total_questions      INTEGER NOT NULL,
  correct_answers      INTEGER NOT NULL DEFAULT 0,
  score_percentage     DECIMAL(5,2) GENERATED ALWAYS AS (
                         CASE
                           WHEN total_questions = 0 THEN 0
                           ELSE ROUND((correct_answers::DECIMAL / total_questions) * 100, 2)
                         END
                       ) STORED,
  is_passed            BOOLEAN GENERATED ALWAYS AS (
                         CASE
                           WHEN total_questions = 0 THEN false
                           ELSE (correct_answers::DECIMAL / total_questions) * 100 >= 80.0
                         END
                       ) STORED,
  time_total_seconds   INTEGER,       -- Total session duration in seconds
  question_results     JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- quiz mode:      [{ question_id, selected_answer, is_correct, time_seconds }]
  -- flashcard mode: [{ question_id, self_rated_confidence, time_seconds }]
  started_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at         TIMESTAMPTZ,   -- NULL if session was abandoned
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_correct_lte_total CHECK (correct_answers <= total_questions),
  CONSTRAINT chk_theme_practice_has_theme CHECK (
    session_type != 'theme_practice' OR theme_id IS NOT NULL
  )
);

-- Indexes as specified in architecture doc
CREATE INDEX idx_quiz_sessions_user_completed
  ON quiz_sessions (user_id, completed_at DESC);

CREATE INDEX idx_quiz_sessions_user_type
  ON quiz_sessions (user_id, session_type);

CREATE INDEX idx_quiz_sessions_mock_scores
  ON quiz_sessions (user_id, completed_at DESC)
  WHERE session_type = 'mock_exam';

-- RLS: users can only see and create their own sessions.
-- No UPDATE policy: sessions are immutable once completed (analytics integrity).
-- No DELETE policy for users: only CASCADE from auth.users deletion (GDPR).
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sessions"
  ON quiz_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
  ON quiz_sessions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
