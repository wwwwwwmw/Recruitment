import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

let pool;

export function getDb() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      console.warn('DATABASE_URL not set; DB calls will fail if used.');
    }
    pool = new Pool({ connectionString, ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined });
  }
  return pool;
}

export async function pingDb() {
  try {
    const client = await getDb().connect();
    const { rows } = await client.query('select 1 as ok');
    client.release();
    return rows[0].ok === 1;
  } catch (e) {
    console.warn('DB ping failed:', e.message);
    return false;
  }
}
