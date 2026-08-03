import { z } from 'zod';

export const payoutFilterSchema = z.object({
  query: z.object({
    group_id: z.string().uuid().optional(),
    status: z.enum(['pending', 'completed', 'rejected']).optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
  }),
});

export const updatePayoutSchema = z.object({
  params: z.object({
    id: z.string().uuid(),
  }),
  body: z.object({
    status: z.enum(['pending', 'completed', 'rejected']).optional(),
    payout_amount: z.number().positive().optional(),
  }),
});
