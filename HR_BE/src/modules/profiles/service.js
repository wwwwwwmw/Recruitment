import { getDb } from '../../config/db.js';
import { validationResult } from 'express-validator';

async function ensureTable(){
  await getDb().query(`
    CREATE TABLE IF NOT EXISTS candidate_profiles (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      scores JSONB,
      extra JSONB,
      created_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now()
    );
  `);
}

export async function getMine(req, res, next){
  try{
    await ensureTable();
    const userId = req.user?.id;
    if(!userId) return res.status(401).json({ message: 'Unauthorized' });
    const { rows } = await getDb().query('SELECT user_id, scores, extra, created_at, updated_at FROM candidate_profiles WHERE user_id=$1', [userId]);
    res.json(rows[0] || { user_id: userId, scores: {}, extra: {} });
  }catch(e){ next(e); }
}

export async function putMine(req, res, next){
  try{
    await ensureTable();
    const userId = req.user?.id;
    if(!userId) return res.status(401).json({ message: 'Unauthorized' });
    const scores = req.body?.scores || {};
    const extra = req.body?.extra || {};
    const { rows } = await getDb().query(
      `INSERT INTO candidate_profiles(user_id, scores, extra)
       VALUES($1,$2,$3)
       ON CONFLICT (user_id) DO UPDATE SET scores=EXCLUDED.scores, extra=EXCLUDED.extra, updated_at=now()
       RETURNING user_id, scores, extra, created_at, updated_at`,
      [userId, scores, extra]
    );
    res.json(rows[0]);
  }catch(e){ next(e); }
}

export async function getByEmail(req, res, next){
  try{
    const errors = validationResult(req);
    if (!errors.isEmpty()){ return res.status(400).json({ message: 'Invalid email' }); }
    // Only admin/recruiter can read others' profiles
    const role = req.user?.role;
    if (role !== 'admin' && role !== 'recruiter') return res.status(403).json({ message: 'Forbidden' });
    const email = (req.query.email || '').toString();
    const db = getDb();
    const u = await db.query('SELECT id FROM users WHERE lower(email)=lower($1)', [email]);
    const userId = u.rows[0]?.id;
    if (!userId) return res.json({ user_id: null, scores: {}, extra: {} });
    const r = await db.query('SELECT user_id, scores, extra, created_at, updated_at FROM candidate_profiles WHERE user_id=$1', [userId]);
    res.json(r.rows[0] || { user_id: userId, scores: {}, extra: {} });
  }catch(e){ next(e); }
}
