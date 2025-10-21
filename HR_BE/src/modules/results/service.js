import { getDb } from '../../config/db.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM results ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { application_id, result, notes } = req.body;
    const { rows } = await getDb().query('INSERT INTO results (application_id, result, notes) VALUES ($1,$2,$3) RETURNING *', [application_id, result, notes || null]);
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM results WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Result not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}
