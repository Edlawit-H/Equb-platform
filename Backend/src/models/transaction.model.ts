export interface Transaction {
  transaction_id: string;
  user_id: string;
  group_id: string | null;
  type: 'top_up' | 'contribution_debit' | 'payout_credit' | 'adjustment';
  amount: number;
  reference_number: string | null;
  status: string;
  created_at: Date;
}
