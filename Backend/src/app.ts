import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { rateLimit } from 'express-rate-limit';
import dotenv from 'dotenv';

import { errorHandler } from './middleware/errorHandler.js';
import { notFound }     from './middleware/notFound.js';
import healthRouter     from './routes/health.js';

dotenv.config();

const app = express();

// ── Security ──────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
  credentials: true,
}));

// ── Rate limiting ─────────────────────────────────────────────────────────────
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
}));

// ── Parsing ───────────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Logging ───────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/health', healthRouter);

// Each developer uncomments their routes as they build them:
// import authRouter         from './routes/auth.js';
// import userRouter         from './routes/users.js';
// import groupRouter        from './routes/groups.js';
// import contributionRouter from './routes/contributions.js';
// import payoutRouter       from './routes/payouts.js';
// import transactionRouter  from './routes/transactions.js';
// import notificationRouter from './routes/notifications.js';
// import reportRouter       from './routes/reports.js';
// import adminRouter        from './routes/admin.js';

// app.use('/api/v1/auth',          authRouter);
// app.use('/api/v1/users',         userRouter);
// app.use('/api/v1/groups',        groupRouter);
// app.use('/api/v1/contributions', contributionRouter);
// app.use('/api/v1/payouts',       payoutRouter);
// app.use('/api/v1/transactions',  transactionRouter);
// app.use('/api/v1/notifications', notificationRouter);
// app.use('/api/v1/reports',       reportRouter);
// app.use('/api/v1/admin',         adminRouter);

// ── Fallbacks ─────────────────────────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

export default app;
