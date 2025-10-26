import pg from 'pg';
import dotenv from 'dotenv';
import { newDb } from 'pg-mem';

dotenv.config();

const { Pool } = pg;

let pool;
let usingMem = false;

export function getDb() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      // In-memory fallback for development
      const db = newDb({ autoCreateForeignKeyIndices: true });
      const memPg = db.adapters.createPg();
      const { Pool: MemPool } = memPg;
      pool = new MemPool();
      usingMem = true;
      console.warn('DATABASE_URL not set; using in-memory database (pg-mem) for development.');
    } else {
      pool = new Pool({ connectionString, ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined });
    }
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

export function isUsingInMemoryDb(){
  return usingMem;
}
