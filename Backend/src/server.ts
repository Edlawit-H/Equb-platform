import app from './app';
import { pool } from './db/pool';

const PORT = process.env.PORT ?? 5000;

const start = async () => {
  try {
    // Test DB connection on startup
    await pool.query('SELECT 1');
    console.log('✅ Database connected');

    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT} [${process.env.NODE_ENV}]`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
};

start();
