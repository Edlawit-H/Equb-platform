ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS cycle_end_date DATE;

ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS contribution_deadline_days INT NOT NULL DEFAULT 1;
