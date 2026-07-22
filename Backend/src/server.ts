import app from './app.js';
import { pool } from './db/pool.js';
import dotenv from 'dotenv';

dotenv.config();

const PORT = process.env.PORT ?? 5000;

const start = async () => {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Database connected');

    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}  [${process.env.NODE_ENV ?? 'development'}]`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
};

start();
