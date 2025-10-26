-- PostgreSQL schema for HR recruitment system

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  role TEXT DEFAULT 'candidate',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS jobs (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  department TEXT,
  location TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS processes (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stages (
  id SERIAL PRIMARY KEY,
  process_id INT NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  stage_order INT NOT NULL,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS applications (
  id SERIAL PRIMARY KEY,
  job_id INT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  resume_url TEXT,
  cover_letter TEXT,
  status TEXT DEFAULT 'submitted',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS evaluations (
  id SERIAL PRIMARY KEY,
  application_id INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  stage_id INT REFERENCES stages(id) ON DELETE SET NULL,
  score NUMERIC(5,2) NOT NULL,
  comments TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS interviews (
  id SERIAL PRIMARY KEY,
  application_id INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMP NOT NULL,
  location TEXT,
  mode TEXT,
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS committees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS committee_members (
  committee_id INT NOT NULL REFERENCES committees(id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (committee_id, user_id)
);

CREATE TABLE IF NOT EXISTS results (
  id SERIAL PRIMARY KEY,
  application_id INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  result TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offers (
  id SERIAL PRIMARY KEY,
  application_id INT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  position TEXT,
  salary NUMERIC(12,2),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Upgrades / safe alterations
-- Link jobs to the poster (recruiter/admin) and optionally to a process
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS posted_by INT REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS process_id INT REFERENCES processes(id) ON DELETE SET NULL;

-- Store the full letter content for offers
ALTER TABLE offers ADD COLUMN IF NOT EXISTS content TEXT;
-- Track who sent the offer (recruiter/admin)
ALTER TABLE offers ADD COLUMN IF NOT EXISTS sender_id INT REFERENCES users(id) ON DELETE SET NULL;

-- Ensure stage order uniqueness within a process
CREATE UNIQUE INDEX IF NOT EXISTS idx_stages_unique_order ON stages(process_id, stage_order);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_jobs_posted_by ON jobs(posted_by);
CREATE INDEX IF NOT EXISTS idx_applications_job_id ON applications(job_id);
CREATE INDEX IF NOT EXISTS idx_offers_application_id ON offers(application_id);

-- Candidate profile data (scores per evaluation criteria + extra resume data)
CREATE TABLE IF NOT EXISTS candidate_profiles (
  user_id INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  scores JSONB,
  extra JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_candidate_profiles_user ON candidate_profiles(user_id);

-- Evaluation criteria catalog used for scoring profiles/applications
CREATE TABLE IF NOT EXISTS evaluation_criteria (
  id SERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  min NUMERIC NOT NULL DEFAULT 0,
  max NUMERIC NOT NULL DEFAULT 100,
  step NUMERIC NOT NULL DEFAULT 1,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
