-- Migration: fix_language_code_sp
-- Align preferred_language CHECK constraint with frontend convention.
-- Frontend uses 'sp' for Spanish; rename 'es' → 'sp' throughout.

UPDATE user_profiles
  SET preferred_language = 'sp'
  WHERE preferred_language = 'es';

ALTER TABLE user_profiles
  DROP CONSTRAINT user_profiles_preferred_language_check;

ALTER TABLE user_profiles
  ADD CONSTRAINT user_profiles_preferred_language_check
  CHECK (preferred_language IN ('fr', 'en', 'sp', 'ar'));
