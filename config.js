// getnaroo.com settings.
// The Supabase "anon" key is designed to be public: what it can do is limited
// by the security rules set up in the Supabase project (see supabase/setup.sql).
window.NAROO = {
  SUPABASE_URL: "",       // e.g. https://abcd1234.supabase.co
  SUPABASE_ANON_KEY: "",  // the project's public anon key
  BUCKET: "memories",
  // The wall opens to everyone at this moment (Naroo's 50th, IST).
  REVEAL_AT: "2026-11-16T00:00:00+05:30",
  MAX_VIDEO_MB: 50,
  MAX_FILES: 6,
};
