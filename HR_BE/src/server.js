import dotenv from 'dotenv';
import app from './app.js';
import { readFile } from 'node:fs/promises';
import { getDb } from './config/db.js';

dotenv.config();

const port = process.env.PORT || 4000;
const host = process.env.HOST || '0.0.0.0';

async function applySchemaIfNeeded(){
  if (process.env.AUTO_APPLY_SCHEMA === 'true') {
    try {
      const sql = await readFile(new URL('../db/schema.sql', import.meta.url), 'utf8');
      const client = await getDb().connect();
      await client.query(sql);
      client.release();
      console.log('Database schema applied.');
    } catch (e) {
      console.warn('Schema apply failed:', e.message);
    }
  }
}

applySchemaIfNeeded().finally(() => {
  app.listen(port, host, () => {
    console.log(`HR recruitment backend listening on ${host}:${port}`);
    const hostForDocs = host === '0.0.0.0' ? 'localhost' : host;
    console.log(`Swagger UI available at http://${hostForDocs}:${port}/api-docs`);
  });
});
