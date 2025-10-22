import { getDb } from '../../config/db.js';

async function ensureTable(){
  await getDb().query(`
    CREATE TABLE IF NOT EXISTS evaluation_criteria (
      id SERIAL PRIMARY KEY,
      key TEXT UNIQUE NOT NULL,
      label TEXT NOT NULL,
      min NUMERIC NOT NULL DEFAULT 0,
      max NUMERIC NOT NULL DEFAULT 100,
      step NUMERIC NOT NULL DEFAULT 1,
      active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now()
    );
  `);
}

export async function list(req, res, next){
  try{
    await ensureTable();
    const { active } = req.query;
    const params = [];
    let sql = 'SELECT id, key, label, min, max, step, active FROM evaluation_criteria';
    if (active === 'true') { sql += ' WHERE active=true'; }
    sql += ' ORDER BY id ASC';
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  }catch(e){ next(e); }
}

export async function create(req, res, next){
  try{
    await ensureTable();
    const { key, label, min=0, max=100, step=1, active=true } = req.body || {};
    const { rows } = await getDb().query(
      `INSERT INTO evaluation_criteria(key, label, min, max, step, active)
       VALUES($1,$2,$3,$4,$5,$6)
       RETURNING id, key, label, min, max, step, active`,
      [key, label, min, max, step, active]
    );
    res.status(201).json(rows[0]);
  }catch(e){ next(e); }
}

export async function updateById(req, res, next){
  try{
    await ensureTable();
    const { id } = req.params;
    const fields = ['key','label','min','max','step','active'];
    const set=[]; const vals=[];
    for (const f of fields){ if (req.body[f] !== undefined){ set.push(`${f}=$${set.length+1}`); vals.push(req.body[f]); } }
    if (!set.length) return res.status(400).json({ message: 'No changes' });
    vals.push(id);
    const { rows, rowCount } = await getDb().query(`UPDATE evaluation_criteria SET ${set.join(',')}, updated_at=now() WHERE id=$${vals.length} RETURNING id, key, label, min, max, step, active`, vals);
    if (!rowCount) return res.status(404).json({ message: 'Not found' });
    res.json(rows[0]);
  }catch(e){ next(e); }
}

export async function removeById(req, res, next){
  try{
    await ensureTable();
    const { id } = req.params;
    await getDb().query('DELETE FROM evaluation_criteria WHERE id=$1', [id]);
    res.json({ ok: true });
  }catch(e){ next(e); }
}
