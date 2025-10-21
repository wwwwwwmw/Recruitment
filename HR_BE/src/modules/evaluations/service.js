import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM evaluations ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { application_id, stage_id, score, comments } = req.body;
    const { rows } = await getDb().query(
      'INSERT INTO evaluations (application_id, stage_id, score, comments) VALUES ($1,$2,$3,$4) RETURNING *',
      [application_id, stage_id || null, score, comments || null]
    );
    // Notify applicant best-effort
    const app = await getDb().query('SELECT email, full_name FROM applications WHERE id=$1', [application_id]);
    if (app.rows[0]) {
      sendEmail({ to: app.rows[0].email, subject: 'Application Update', text: `Hi ${app.rows[0].full_name}, your application has been evaluated.` }).catch(()=>{});
    }
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM evaluations WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Evaluation not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}
