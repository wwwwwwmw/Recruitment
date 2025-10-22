import { validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import { getDb } from '../../config/db.js';

function handleValidation(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const err = new Error('Validation error');
    err.status = 400;
    err.details = errors.array();
    throw err;
  }
}

export async function list(req, res, next) {
  try {
    const db = getDb();
    const { q } = req.query;
    let sql = 'SELECT id, full_name, email, role, created_at, updated_at FROM users';
    const params = [];
    if (q) {
      params.push(`%${q.toLowerCase()}%`);
      sql += ` WHERE lower(full_name) LIKE $${params.length} OR lower(email) LIKE $${params.length}`;
    }
    sql += ' ORDER BY id DESC';
    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const db = getDb();
    const { id } = req.params;
    const { rows } = await db.query('SELECT id, full_name, email, role, created_at, updated_at FROM users WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    handleValidation(req);
    const db = getDb();
    const { full_name, email, role = 'candidate', password } = req.body;
    const password_hash = password ? await bcrypt.hash(password, 10) : null;
    const { rows } = await db.query(
      'INSERT INTO users(full_name, email, role, password_hash) VALUES($1,$2,$3,$4) RETURNING id, full_name, email, role, created_at, updated_at',
      [full_name, email, role, password_hash]
    );
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function update(req, res, next) {
  try {
    handleValidation(req);
    const db = getDb();
    const { id } = req.params;
    const { full_name, email, role, password } = req.body;
    const set = [];
    const params = [];
    if (full_name !== undefined) { params.push(full_name); set.push(`full_name=$${params.length}`); }
    if (email !== undefined) { params.push(email); set.push(`email=$${params.length}`); }
    if (role !== undefined) { params.push(role); set.push(`role=$${params.length}`); }
    if (password !== undefined) {
      const hash = await bcrypt.hash(password, 10);
      params.push(hash); set.push(`password_hash=$${params.length}`);
    }
    params.push(id);
    if (!set.length) return res.status(400).json({ message: 'No fields to update' });
    const { rows } = await db.query(
      `UPDATE users SET ${set.join(', ')}, updated_at=now() WHERE id=$${params.length} RETURNING id, full_name, email, role, created_at, updated_at`,
      params
    );
    if (!rows[0]) return res.status(404).json({ message: 'Not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function remove(req, res, next) {
  try {
    const db = getDb();
    const { id } = req.params;
    await db.query('DELETE FROM users WHERE id=$1', [id]);
    res.json({ ok: true });
  } catch (e) { next(e); }
}

export async function resetPassword(req, res, next) {
  try {
    handleValidation(req);
    const db = getDb();
    const { id } = req.params;
    const { password } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const { rowCount } = await db.query('UPDATE users SET password_hash=$1, updated_at=now() WHERE id=$2', [hash, id]);
    if (!rowCount) return res.status(404).json({ message: 'Not found' });
    res.json({ ok: true });
  } catch (e) { next(e); }
}
