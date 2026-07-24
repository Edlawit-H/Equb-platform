import { z } from 'zod';

export const topUpSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
  }),
});

export const transactionFilterSchema = z.object({
  query: z.object({
    type: z.enum(['top_up', 'contribution_debit', 'payout_credit', 'adjustment']).optional(),
    group_id: z.string().uuid().optional(),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
  }),
});
