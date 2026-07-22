import type { Request, Response, NextFunction } from 'express';

export const getProfile = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const updateProfile = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const uploadAvatar = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const changePassword = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const deleteAccount = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getUserById = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const searchUsers = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getUserGroups = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getUserLoansStub = async (_req: Request, res: Response, _next: NextFunction): Promise<void> => {
  res.status(501).json({ status: 'error', message: 'Not implemented' });
};
