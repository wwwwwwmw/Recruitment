import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM applications ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { job_id, full_name, email, phone, resume_url, cover_letter } = req.body;
    const { rows } = await getDb().query(
      'INSERT INTO applications (job_id, full_name, email, phone, resume_url, cover_letter) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [job_id, full_name, email, phone || null, resume_url || null, cover_letter || null]
    );
    // Send confirmation (best-effort)
    sendEmail({ to: email, subject: 'Application Received', text: `Hi ${full_name}, we received your application.` }).catch(()=>{});
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM applications WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Application not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function updateStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body; // submitted, screening, interviewed, offered, rejected, hired
    const { rows } = await getDb().query('UPDATE applications SET status=$1, updated_at=now() WHERE id=$2 RETURNING *', [status, id]);
    res.json(rows[0]);
  } catch (e) { next(e); }
}
