-- Migration: create_study_progress
-- Cumulative per-question tracking. One row per user+question pair.
-- This is the spaced repetition backbone.

CREATE TABLE study_progress (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id        TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  attempts           INTEGER NOT NULL DEFAULT 0,
  correct_attempts   INTEGER NOT NULL DEFAULT 0,
  last_answered_at   TIMESTAMPTZ,
  confidence_level   INTEGER CHECK (confidence_level BETWEEN 1 AND 5),  -- 1=No idea, 5=Mastered
  last_self_rated_at TIMESTAMPTZ,    -- Set during flashcard mode self-rating
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_study_progress_user_question UNIQUE (user_id, question_id),
  CONSTRAINT chk_correct_lte_attempts CHECK (correct_attempts <= attempts)
);

-- Indexes as specified in architecture doc
CREATE INDEX idx_study_progress_user_confidence
  ON study_progress (user_id, confidence_level);

CREATE INDEX idx_study_progress_user_question
  ON study_progress (user_id, question_id);

CREATE TRIGGER trg_study_progress_updated_at
  BEFORE UPDATE ON study_progress
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- RLS: users can only read and write their own progress
ALTER TABLE study_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own study progress"
  ON study_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study progress"
  ON study_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study progress"
  ON study_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
