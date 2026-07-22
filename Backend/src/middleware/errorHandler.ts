import type { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError.js';

export const errorHandler = (
  err: Error | AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    const body: Record<string, unknown> = {
      status: 'error',
      message: err.message,
    };
    if (err.details !== undefined) {
      body['details'] = err.details;
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
