export interface User {
  user_id: string;
  full_name: string;
  phone_number: string;
  email: string | null;
  password_hash: string;
  profile_image: string | null;
  role: 'member' | 'system_admin';
  status: 'pending_verification' | 'active' | 'suspended';
  wallet_balance: number;
  biometric_enabled: boolean;
  is_deleted: boolean;
  created_at: Date;
}
