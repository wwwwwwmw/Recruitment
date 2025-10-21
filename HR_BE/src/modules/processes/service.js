import { getDb } from '../../config/db.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM processes ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { name, stages } = req.body; // stages: [{name, order,index?}]
    const { rows } = await getDb().query('INSERT INTO processes (name) VALUES ($1) RETURNING *', [name]);
    const process = rows[0];
    for (let i = 0; i < stages.length; i++) {
      const s = stages[i];
      await getDb().query('INSERT INTO stages (process_id, name, stage_order) VALUES ($1,$2,$3)', [process.id, s.name, s.stage_order || i + 1]);
    }
    res.status(201).json(process);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const p = await getDb().query('SELECT * FROM processes WHERE id=$1', [id]);
    if (!p.rows[0]) return res.status(404).json({ message: 'Process not found' });
    const s = await getDb().query('SELECT * FROM stages WHERE process_id=$1 ORDER BY stage_order', [id]);
    res.json({ ...p.rows[0], stages: s.rows });
  } catch (e) { next(e); }
}

export async function updateById(req, res, next) {
  try {
    const { id } = req.params;
    const { name, stages } = req.body;
    const { rows } = await getDb().query('UPDATE processes SET name=COALESCE($1,name), updated_at=now() WHERE id=$2 RETURNING *', [name, id]);
    if (stages) {
      await getDb().query('DELETE FROM stages WHERE process_id=$1', [id]);
      for (let i = 0; i < stages.length; i++) {
        const s = stages[i];
        await getDb().query('INSERT INTO stages (process_id, name, stage_order) VALUES ($1,$2,$3)', [id, s.name, s.stage_order || i + 1]);
      }
    }
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    const { id } = req.params;
    await getDb().query('DELETE FROM stages WHERE process_id=$1', [id]);
    await getDb().query('DELETE FROM processes WHERE id=$1', [id]);
    res.json({ success: true });
  } catch (e) { next(e); }
}
