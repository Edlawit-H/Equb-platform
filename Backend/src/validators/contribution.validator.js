import { z } from 'zod';

export const payContributionSchema = z.object({
  body: z.object({
    group_id: z.string().uuid(),
    cycle_number: z.number().int().positive(),
  }),
});

export const bulkContributionSchema = z.object({
  body: z.object({
    group_id: z.string().uuid(),
    cycle_number: z.number().int().positive(),
    member_ids: z.array(z.string().uuid()).min(1).max(50),
  }),
});

export const manualContributionSchema = z.object({
  body: z.object({
    member_id: z.string().uuid(),
    group_id: z.string().uuid(),
    cycle_number: z.number().int().positive(),
    paid_date: z.string().datetime().optional(),
  }),
});
