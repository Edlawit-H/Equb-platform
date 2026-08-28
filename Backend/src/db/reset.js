import { pool } from './pool.js';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

async function resetDatabase() {
  const client = await pool.connect();
  try {
    process.stdout.write('Dropping all existing tables...\n');
    await client.query('DROP SCHEMA public CASCADE;');
    await client.query('CREATE SCHEMA public;');
    await client.query('GRANT ALL ON SCHEMA public TO postgres;');
    await client.query('GRANT ALL ON SCHEMA public TO public;');

    process.stdout.write('Creating migrations tracking table...\n');
    await client.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT NOW()
      )
    `);

    const files = fs.readdirSync(MIGRATIONS_DIR)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    process.stdout.write(`Running ${files.length} fresh migration files...\n`);
    for (const file of files) {
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
      await client.query(sql);
      await client.query('INSERT INTO _migrations (filename) VALUES ($1)', [file]);
      process.stdout.write(`  ✓ Executed: ${file}\n`);
    }

    process.stdout.write('\nDatabase reset and fresh migrations completed successfully!\n');
  } catch (err) {
    process.stderr.write(`Reset failed: ${String(err)}\n`);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

resetDatabase();
