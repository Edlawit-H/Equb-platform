export interface Payout {
  payout_id: string;
  group_id: string;
  member_id: string;
  payout_amount: number;
  payout_date: Date;
  cycle_number: number;
  status: 'pending' | 'completed' | 'rejected';
  created_at: Date;
}
