import type { Request, Response, NextFunction } from 'express';
import type { AnyZodObject } from 'zod';

export const validate = (schema: AnyZodObject) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params,
    });

    if (!result.success) {
      _res.status(400).json({
        status: 'error',
        message: 'Validation failed',
        details: result.error.flatten().fieldErrors,
      });
      return;
    }

    next();
  };
