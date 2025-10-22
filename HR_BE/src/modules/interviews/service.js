import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';
import { validationResult } from 'express-validator';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM interviews ORDER BY scheduled_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    // Validate request body
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: 'Invalid input', errors: errors.array() });
    }

    const { application_id, scheduled_at, location, mode } = req.body;

    // Ensure application exists to prevent FK violation 500s
    const app = await getDb().query('SELECT id, email, full_name FROM applications WHERE id=$1', [application_id]);
    if (!app.rows[0]) return res.status(400).json({ message: 'Application not found' });

    const { rows } = await getDb().query(
      'INSERT INTO interviews (application_id, scheduled_at, location, mode) VALUES ($1,$2,$3,$4) RETURNING *',
      [application_id, scheduled_at, location || null, mode || null]
    );

    // Fire-and-forget email notification
    sendEmail({
      to: app.rows[0].email,
      subject: 'Interview Scheduled',
      text: `Hi ${app.rows[0].full_name}, your interview is scheduled at ${scheduled_at}.`
    }).catch(() => {});

    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM interviews WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Interview not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function updateById(req, res, next) {
  try {
    const { id } = req.params;
    const fields = ['scheduled_at','location','mode','status'];
    const updates=[]; const values=[];
    for (const f of fields) if (req.body[f]!==undefined){ updates.push(`${f}=$${updates.length+1}`); values.push(req.body[f]); }
    if (!updates.length) return res.json({ message: 'No changes' });
    values.push(id);
    const { rows } = await getDb().query(`UPDATE interviews SET ${updates.join(',')}, updated_at=now() WHERE id=$${values.length} RETURNING *`, values);
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    const { id } = req.params;
    await getDb().query('DELETE FROM interviews WHERE id=$1', [id]);
    res.json({ success: true });
  } catch (e) { next(e); }
}
