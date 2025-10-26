import pg from 'pg';
import dotenv from 'dotenv';
import { newDb } from 'pg-mem';
import { readFileSync } from 'node:fs';

dotenv.config();

const { Pool } = pg;

let pool;
let usingMem = false;

export function getDb() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      // Development fallback: in-memory Postgres using pg-mem
      console.warn('DATABASE_URL not set; using in-memory database (pg-mem) for development.');
      const mem = newDb({ autoCreateForeignKeyIndices: true });
      try {
        const schemaPath = new URL('../../db/schema.sql', import.meta.url);
        const sql = readFileSync(schemaPath, 'utf8');
        mem.public.none(sql);
        console.log('In-memory schema applied.');
      } catch (e) {
        console.warn('Unable to apply schema to in-memory DB:', e.message);
      }
      const { Pool: MemPool } = mem.adapters.createPg();
      pool = new MemPool();
      usingMem = true;
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

export function isUsingInMemoryDb(){ return usingMem; }
