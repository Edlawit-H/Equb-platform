import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    full_name: z.string().min(2).max(150),
    phone_number: z.string().regex(/^\+?[1-9]\d{1,14}$/),
    email: z.string().email().optional(),
    password: z.string().min(8),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    phone_number: z.string().optional(),
    email: z.string().email().optional(),
    password: z.string().min(1),
  }).refine((data) => data.phone_number || data.email, {
    message: 'Phone number or email is required',
  }),
});

export const otpSchema = z.object({
  body: z.object({
    phone_number: z.string().optional(),
    email: z.string().email().optional(),
    otp: z.string().length(6).regex(/^\d{6}$/),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    otp: z.string().length(6),
    new_password: z.string().min(8),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    current_password: z.string().min(1),
    new_password: z.string().min(8),
  }),
});
