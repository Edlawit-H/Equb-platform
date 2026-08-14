import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'equb_default_secret_key_change_in_production';

export const generateToken = (user) => {
  return jwt.sign(
    {
      user_id: user.user_id,
      phone_number: user.phone_number,
      role: user.role
    },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
};
