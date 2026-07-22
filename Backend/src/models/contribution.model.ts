export interface Contribution {
  contribution_id: string;
  member_id: string;
  group_id: string;
  cycle_number: number;
  amount: number;
  due_date: Date;
  paid_date: Date | null;
  status: 'pending' | 'paid' | 'overdue';
  created_at: Date;
}
