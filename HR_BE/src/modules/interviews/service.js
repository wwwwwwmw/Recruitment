import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM interviews ORDER BY scheduled_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { application_id, scheduled_at, location, mode } = req.body;
    const { rows } = await getDb().query(
      'INSERT INTO interviews (application_id, scheduled_at, location, mode) VALUES ($1,$2,$3,$4) RETURNING *',
      [application_id, scheduled_at, location || null, mode || null]
    );
    const app = await getDb().query('SELECT email, full_name FROM applications WHERE id=$1', [application_id]);
    if (app.rows[0]) {
      sendEmail({ to: app.rows[0].email, subject: 'Interview Scheduled', text: `Hi ${app.rows[0].full_name}, your interview is scheduled at ${scheduled_at}.` }).catch(()=>{});
    }
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
