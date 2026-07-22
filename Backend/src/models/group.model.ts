export interface EqubGroup {
  group_id: string;
  group_name: string;
  description: string | null;
  admin_id: string;
  invitation_code: string;
  contribution_amount: number;
  cycle_duration: 7 | 14 | 30;
  max_members: number;
  current_cycle: number;
  selection_mode: 'positional' | 'random';
  start_date: Date | null;
  end_date: Date | null;
  status: 'pending' | 'ready' | 'active' | 'completed' | 'cancelled';
  is_deleted: boolean;
  created_at: Date;
}

export interface GroupMember {
  member_id: string;
  user_id: string;
  group_id: string;
  join_date: Date;
  position_in_cycle: number;
  role: 'admin' | 'co_admin' | 'member';
  status: 'active' | 'removed' | 'left';
}
