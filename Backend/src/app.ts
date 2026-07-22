import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { rateLimit } from 'express-rate-limit';
import dotenv from 'dotenv';

import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import healthRouter from './routes/health';

// ── Load env ──────────────────────────────────────────────────────────────────
dotenv.config();

const app = express();

// ── Security middleware ────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
  credentials: true,
}));

// ── General rate limiter ───────────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// ── Request parsing ────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── HTTP logging ───────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ── Routes ─────────────────────────────────────────────────────────────────────
app.use('/health', healthRouter);

// Feature routes (mounted here by each developer as they build them)
// app.use('/api/v1/auth',          authRouter);
// app.use('/api/v1/users',         userRouter);
// app.use('/api/v1/groups',        groupRouter);
// app.use('/api/v1/contributions', contributionRouter);
// app.use('/api/v1/payouts',       payoutRouter);
// app.use('/api/v1/transactions',  transactionRouter);
// app.use('/api/v1/notifications', notificationRouter);
// app.use('/api/v1/reports',       reportRouter);
// app.use('/api/v1/admin',         adminRouter);

// ── 404 handler ────────────────────────────────────────────────────────────────
app.use(notFound);

// ── Global error handler ───────────────────────────────────────────────────────
app.use(errorHandler);

export default app;
