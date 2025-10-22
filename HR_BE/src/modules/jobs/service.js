import slugify from 'slugify';
import { getDb } from '../../config/db.js';

export async function list(req, res, next) {
  try {
    const mine = req.query.mine === 'true';
    if (mine && req.user && (req.user.role === 'admin' || req.user.role === 'recruiter')) {
      const { rows } = await getDb().query('SELECT * FROM jobs WHERE posted_by=$1 ORDER BY created_at DESC', [req.user.id]);
      return res.json(rows);
    }
    const { rows } = await getDb().query('SELECT * FROM jobs ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { title, slug, description, department, location } = req.body;
    const s = slug || slugify(title, { lower: true, strict: true });
    const postedBy = req.user?.id || null;
    const { rows } = await getDb().query(
      'INSERT INTO jobs (title, slug, description, department, location, posted_by) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [title, s, description, department || null, location || null, postedBy]
    );
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM jobs WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Job not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function updateById(req, res, next) {
  try {
    const { id } = req.params;
    const fields = ['title','slug','description','department','location'];
    const updates = [];
    const values = [];
    fields.forEach((f, i) => {
      if (req.body[f] !== undefined) {
        updates.push(`${f}=$${updates.length+1}`);
        values.push(req.body[f]);
      }
    });
    if (!updates.length) return res.json({ message: 'No changes' });
    // Restrict recruiters to only their own jobs
    if (req.user?.role === 'recruiter') {
      values.push(id);
      values.push(req.user.id);
      const { rows, rowCount } = await getDb().query(
        `UPDATE jobs SET ${updates.join(',')}, updated_at=now() WHERE id=$${values.length-1} AND posted_by=$${values.length} RETURNING *`,
        values
      );
      if (!rowCount) return res.status(403).json({ message: 'Bạn chỉ có thể sửa công việc do bạn đăng' });
      return res.json(rows[0]);
    }
    // Admin can edit any
    values.push(id);
    const { rows } = await getDb().query(`UPDATE jobs SET ${updates.join(',')}, updated_at=now() WHERE id=$${values.length} RETURNING *`, values);
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    const { id } = req.params;
    if (req.user?.role === 'recruiter') {
      const { rowCount } = await getDb().query('DELETE FROM jobs WHERE id=$1 AND posted_by=$2', [id, req.user.id]);
      if (!rowCount) return res.status(403).json({ message: 'Bạn chỉ có thể xóa công việc do bạn đăng' });
      return res.json({ success: true });
    }
    await getDb().query('DELETE FROM jobs WHERE id=$1', [id]);
    res.json({ success: true });
  } catch (e) { next(e); }
}
