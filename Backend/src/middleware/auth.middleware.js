import jwt from 'jsonwebtoken';
import { AppError } from '../utils/AppError.js';

export const protect = (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new AppError('No token provided', 401));
  }

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET ?? '');
    req.userId = decoded.userId;
    req.userRole = decoded.role;
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
