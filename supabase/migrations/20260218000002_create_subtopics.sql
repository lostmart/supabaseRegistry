-- Migration: create_subtopics
-- Learning units within each theme (e.g. "Laïcité" within Principes et Valeurs).

CREATE TABLE subtopics (
  id          TEXT PRIMARY KEY,
  theme_id    TEXT NOT NULL REFERENCES themes(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  subtitle    TEXT,
  description TEXT,
  key_points  JSONB,          -- Array of bullet point strings
  exam_tip    TEXT,           -- Strategic exam advice
  image       TEXT,           -- Asset identifier
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subtopics_theme_id ON subtopics (theme_id);

-- RLS: content table — any authenticated user can read
ALTER TABLE subtopics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read subtopics"
  ON subtopics FOR SELECT
  TO authenticated
  USING (true);
