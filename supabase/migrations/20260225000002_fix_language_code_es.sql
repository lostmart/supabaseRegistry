-- Migration: fix_language_code_es
-- Revert non-standard 'sp' back to ISO 639-1 'es' for Spanish.
-- Supersedes migration 20260225000001_fix_language_code_sp.sql.

UPDATE user_profiles
  SET preferred_language = 'es'
  WHERE preferred_language = 'sp';

ALTER TABLE user_profiles
  DROP CONSTRAINT user_profiles_preferred_language_check;

ALTER TABLE user_profiles
  ADD CONSTRAINT user_profiles_preferred_language_check
  CHECK (preferred_language IN ('fr', 'en', 'es', 'ar'));
