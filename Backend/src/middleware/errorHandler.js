import { AppError } from '../utils/AppError.js';

export const errorHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    const body = {
      status: 'error',
      message: err.message,
    };
    if (err.details !== undefined) {
      body.details = err.details;
    }
    res.status(err.statusCode).json(body);
    return;
  }

  res.status(500).json({
    status: 'error',
    message: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
  });
};
