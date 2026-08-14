import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'equb_default_secret_key_change_in_production';
const ACCESS_EXPIRES = '15m';
const REFRESH_EXPIRES = '30d';

export function generateAccessToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: ACCESS_EXPIRES });
}

export function generateRefreshToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: REFRESH_EXPIRES });
}
