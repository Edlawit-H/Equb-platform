ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS cycle_end_date DATE;

ALTER TABLE equb_groups ADD COLUMN IF NOT EXISTS total_cycles INT;

ALTER TABLE equb_groups DROP COLUMN IF EXISTS selection_mode;

ALTER TABLE equb_groups DROP COLUMN IF EXISTS contribution_deadline_days;
