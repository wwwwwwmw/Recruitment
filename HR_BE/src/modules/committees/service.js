import { getDb } from '../../config/db.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM committees ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { name, description } = req.body;
    const { rows } = await getDb().query('INSERT INTO committees (name, description) VALUES ($1,$2) RETURNING *', [name, description || null]);
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function addMember(req, res, next) {
  try {
    const { id } = req.params; // committee id
    const { user_id } = req.body;
    await getDb().query('INSERT INTO committee_members (committee_id, user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING', [id, user_id]);
    res.json({ success: true });
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const c = await getDb().query('SELECT * FROM committees WHERE id=$1', [id]);
    if (!c.rows[0]) return res.status(404).json({ message: 'Committee not found' });
    const m = await getDb().query('SELECT u.* FROM committee_members cm JOIN users u ON u.id=cm.user_id WHERE cm.committee_id=$1', [id]);
    res.json({ ...c.rows[0], members: m.rows });
  } catch (e) { next(e); }
}
