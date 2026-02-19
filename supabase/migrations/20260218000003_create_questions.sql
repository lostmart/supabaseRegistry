-- Migration: create_questions
-- MCQ exam questions. Human-readable IDs encode level, theme, type, and number.
-- ID format: q_{level}_{theme}_{type}_{number}
--   e.g. q_csp_pv_k_001, q_cr_inst_s_012, q_nat_hist_k_028

CREATE TABLE questions (
  id                 TEXT PRIMARY KEY,
  theme_id           TEXT NOT NULL REFERENCES themes(id) ON DELETE RESTRICT,
  exam_type          TEXT NOT NULL CHECK (exam_type IN ('CSP', 'CR', 'NAT')),
  question_type      TEXT NOT NULL CHECK (question_type IN ('knowledge', 'situational')),
  question_text_fr   TEXT NOT NULL,   -- Always in French (exam language)
  question_text_en   TEXT,            -- English translation
  options            JSONB NOT NULL,  -- Array of { label, text_fr, text_en }
  correct_answer     TEXT NOT NULL,   -- Label of the correct option
  explanation_fr     TEXT,            -- Why the answer is correct (French)
  explanation_en     TEXT,            -- Why the answer is correct (English)
  source             JSONB,           -- { url, name, verified_date }
  tags               TEXT[],          -- e.g. ['trap_question', 'laicite', '1905_law']
  difficulty         INTEGER CHECK (difficulty BETWEEN 1 AND 5),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_questions_theme_id   ON questions (theme_id);
CREATE INDEX idx_questions_exam_type  ON questions (exam_type);
CREATE INDEX idx_questions_type_theme ON questions (exam_type, theme_id);

-- RLS: freemium enforcement at database level
--   CSP questions → all authenticated users
--   CR + NAT questions → see migration 000004 (requires user_profiles to exist first)
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "CSP questions available to all authenticated users"
  ON questions FOR SELECT
  TO authenticated
  USING (exam_type = 'CSP');
