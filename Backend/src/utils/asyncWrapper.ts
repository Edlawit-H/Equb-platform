import type { Request, Response, NextFunction, RequestHandler } from 'express';

/**
 * Wraps async route handlers so errors are forwarded to the global error handler.
 * Usage: router.get('/path', asyncWrapper(async (req, res) => { ... }))
 */
export const asyncWrapper = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
): RequestHandler =>
  (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
