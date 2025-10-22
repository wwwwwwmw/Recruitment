import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
    const { job_id, q, mine } = req.query;

    // Base query and params
    let sql = 'SELECT a.* FROM applications a';
    const params = [];
    const where = [];

    // Optional join to jobs for recruiter scoping or job filter
    if ((req.user && req.user.role === 'recruiter') || job_id) {
      sql += ' JOIN jobs j ON j.id=a.job_id';
    }

    // Candidate: when mine=true, restrict to own email
    if (req.user && req.user.role === 'candidate' && mine === 'true') {
      params.push(req.user.email);
      where.push(`a.email=$${params.length}`);
    }

    // Recruiter: when mine=true, restrict to jobs posted by me
    if (req.user && req.user.role === 'recruiter' && mine === 'true') {
      params.push(req.user.id);
      where.push(`j.posted_by=$${params.length}`);
    }

    // Filter by job_id
    if (job_id) {
      params.push(job_id);
      where.push(`a.job_id=$${params.length}`);
    }

    // Search by name/email
    if (q) {
      params.push(`%${q}%`);
      params.push(`%${q}%`);
      where.push(`(a.full_name ILIKE $${params.length-1} OR a.email ILIKE $${params.length})`);
    }

    if (where.length) sql += ' WHERE ' + where.join(' AND ');
    sql += ' ORDER BY a.created_at DESC';

    const { rows } = await getDb().query(sql, params);
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
