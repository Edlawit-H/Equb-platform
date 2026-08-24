ALTER TABLE equb_groups
  DROP CONSTRAINT IF EXISTS chk_groups_cycle_duration;

ALTER TABLE equb_groups
  ADD CONSTRAINT chk_groups_cycle_duration
  CHECK (cycle_duration IN (1, 7, 14, 30));