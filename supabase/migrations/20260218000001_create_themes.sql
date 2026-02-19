-- Migration: create_themes
-- Stores the 5 official exam categories as educational content containers.

CREATE TABLE themes (
  id           TEXT PRIMARY KEY,           -- e.g. 'pv', 'inst', 'dd', 'hist', 'vie'
  title        TEXT NOT NULL,              -- French title
  title_en     TEXT NOT NULL,              -- English title
  description  TEXT,
  color_scheme TEXT,                       -- For UI theming
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed the 5 official themes
INSERT INTO themes (id, title, title_en, description, color_scheme) VALUES
  ('pv',   'Principes et valeurs de la République',  'Principles and Values of the Republic',         NULL, NULL),
  ('inst', 'Système institutionnel et politique',    'Institutional and Political System',            NULL, NULL),
  ('dd',   'Droits et devoirs',                      'Rights and Duties',                             NULL, NULL),
  ('hist', 'Histoire, géographie et culture',        'History, Geography and Culture',                NULL, NULL),
  ('vie',  'Vivre dans la société française',        'Living in French Society',                      NULL, NULL);

-- RLS: content table — any authenticated user can read
ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read themes"
  ON themes FOR SELECT
  TO authenticated
  USING (true);
