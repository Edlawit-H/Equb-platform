import type { Request, Response, NextFunction } from 'express';

export const getWallet = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const topUpWallet = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getTransactions = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getTransactionById = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getTransactionStats = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const getGroupTransactions = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const exportTransactions = async (_req: Request, _res: Response, _next: NextFunction): Promise<void> => {
};

export const refundTransaction = async (_req: Request, res: Response, _next: NextFunction): Promise<void> => {
  res.status(501).json({ status: 'error', message: 'Not implemented' });
};
