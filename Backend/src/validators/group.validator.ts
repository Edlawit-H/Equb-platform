import { z } from 'zod';

export const createGroupSchema = z.object({
  body: z.object({
    group_name: z.string().min(3).max(100),
    description: z.string().max(500).optional(),
    contribution_amount: z.number().positive(),
    cycle_duration: z.union([z.literal(7), z.literal(14), z.literal(30)]),
    max_members: z.number().int().min(2).max(50),
    selection_mode: z.enum(['positional', 'random']).default('positional'),
  }),
});

export const updateGroupSchema = z.object({
  body: z.object({
    group_name: z.string().min(3).max(100).optional(),
    description: z.string().max(500).optional(),
  }),
});

export const joinGroupSchema = z.object({
  body: z.object({
    invitation_code: z.string().length(8),
  }),
});
