import jwt from 'jsonwebtoken';
import { AppError } from '../utils/AppError.js';

const JWT_SECRET = process.env.JWT_SECRET || 'equb_default_secret_key_change_in_production';

export const protect = (req, _res, next) => {
  // Support token in Authorization header OR as ?token= query param (for direct browser download links)
  const header = req.headers.authorization;
  const queryToken = req.query.token;

  let token;
  if (header && header.startsWith('Bearer ')) {
    token = header.split(' ')[1];
  } else if (queryToken) {
    token = queryToken;
  } else {
    return next(new AppError('No token provided', 401));
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId;
    req.userRole = decoded.role;
    req.user = decoded;
    next();
  } catch {
    next(new AppError('Invalid or expired token', 401));
  }
};

export const requireRole = (...roles) => (req, _res, next) => {
  if (!req.userRole || !roles.includes(req.userRole)) {
    return next(new AppError('Forbidden', 403));
  }
  next();
};
