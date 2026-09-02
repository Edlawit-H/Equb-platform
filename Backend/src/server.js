import dotenv from 'dotenv';
import app from './app.js';
import { pool } from './db/pool.js';
import { startCronJobs } from './services/cron.service.js';

dotenv.config();

const PORT = process.env.PORT ?? 5000;

const start = async () => {
  try {
    await pool.query('SELECT 1');
    process.stdout.write('Database connection successful.\n');
    startCronJobs();
  } catch (err) {
    process.stderr.write(`[WARNING] Database connection failed: ${err.message || String(err)}\n`);
    process.stderr.write('Ensure PostgreSQL is running and credentials in .env are correct.\n');
  }

  const server = app.listen(PORT, () => {
    process.stdout.write(`Server running on http://localhost:${PORT}\n`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      process.stderr.write(`Port ${PORT} is already in use. Stop the existing process or change PORT in your .env file.\n`);
      process.exit(1);
    }
    throw err;
  });
};

start();
