import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { rateLimit } from 'express-rate-limit';
import dotenv from 'dotenv';
import { errorHandler } from './middleware/errorHandler.js';
import { notFound } from './middleware/notFound.js';
import healthRouter from './routes/health.js';
import authRouter from './routes/auth.routes.js';
import usersRouter from './routes/users.routes.js';
import groupsRouter from './routes/groups.routes.js';
import contributionsRouter from './routes/contributions.routes.js';
import payoutsRouter from './routes/payouts.routes.js';
import transactionsRouter from './routes/transactions.routes.js';
import notificationsRouter from './routes/notifications.routes.js';
import reportsRouter from './routes/reports.routes.js';
import adminRouter from './routes/admin.routes.js';

dotenv.config();

const app = express();

// Render sits behind one trusted reverse proxy. Preserve the real client IP
// so rate limits are not shared by every user behind the proxy.
app.set('trust proxy', 1);

app.use(helmet());

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ?.split(',')
  .map((origin) => origin.trim())
  .filter(Boolean) ?? [];

app.use(cors({
  origin: (origin, callback) => {
    // Non-browser clients (Postman, mobile apps)
    if (!origin) {
      callback(null, true);
      return;
    }

    // Dev: Flutter web uses random localhost ports
    if (process.env.NODE_ENV !== 'production') {
      if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        callback(null, true);
        return;
      }
    }

    if (allowedOrigins.length === 0 || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error(`CORS blocked for origin: ${origin}`));
  },
  credentials: true,
}));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

app.get('/', (_req, res) => {
  res.status(200).json({
    name: 'Equb Mobile Application API',
    version: '1.0.0',
    status: 'running',
    healthCheck: '/health',
    apiPrefix: '/api/v1',
  });
});

app.use('/health', healthRouter);
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/users', usersRouter);
app.use('/api/v1/groups', groupsRouter);
app.use('/api/v1/contributions', contributionsRouter);
app.use('/api/v1/payouts', payoutsRouter);
app.use('/api/v1/transactions', transactionsRouter);
app.use('/api/v1/notifications', notificationsRouter);
app.use('/api/v1/reports', reportsRouter);
app.use('/api/v1/admin', adminRouter);

app.use(notFound);
app.use(errorHandler);

export default app;
