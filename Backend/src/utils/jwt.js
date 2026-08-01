
import jwt from 'jsonwebtoken';

export const generateAccessToken = (user) => {
  return jwt.sign(
    { id: user.user_id },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );
};