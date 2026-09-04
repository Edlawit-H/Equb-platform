-- Ensure no member can ever receive more than one completed or pending payout in the same group
CREATE UNIQUE INDEX IF NOT EXISTS unique_payout_member_per_group 
ON payouts(group_id, member_id) 
WHERE status IN ('completed', 'pending');
