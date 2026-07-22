import dotenv from 'dotenv';
import app from './app.js';
import { pool } from './db/pool.js';
import { startCronJobs } from './services/cron.service.js';

dotenv.config();

const PORT = process.env.PORT ?? 5000;

const start = async (): Promise<void> => {
  try {
    await pool.query('SELECT 1');
    startCronJobs();
    app.listen(PORT, () => {
      process.stdout.write(`Server running on port ${PORT}\n`);
    });
  } catch (err) {
    process.stderr.write(`Failed to start server: ${String(err)}\n`);
    process.exit(1);
  }
};

start();
