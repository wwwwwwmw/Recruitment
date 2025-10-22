import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
  const { mine, job_id, q, sender_id } = req.query;
  let sql = 'SELECT o.*, a.full_name, a.email, a.job_id, j.title as job_title, u.full_name AS sender_name, u.email AS sender_email FROM offers o';
    const params = [];
    const where = [];

    // Join to applications for candidate filter and search
  sql += ' JOIN applications a ON a.id=o.application_id';
  sql += ' JOIN jobs j ON j.id=a.job_id';
  sql += ' LEFT JOIN users u ON u.id=o.sender_id';

    // For recruiter filtering, join to jobs
    // jobs already joined above

    if (req.user && req.user.role === 'candidate' && mine === 'true') {
      params.push(req.user.email);
      where.push(`a.email=$${params.length}`);
    }
    if (req.user && req.user.role === 'recruiter' && mine === 'true') {
      // Recruiter sees offers they sent, or offers for jobs they posted
      params.push(req.user.id);
      params.push(req.user.id);
      where.push(`(o.sender_id=$${params.length-1} OR j.posted_by=$${params.length})`);
    }
    if (sender_id && req.user && req.user.role === 'admin') {
      params.push(sender_id);
      where.push(`o.sender_id=$${params.length}`);
    }
    if (job_id) {
      params.push(job_id);
      where.push(`a.job_id=$${params.length}`);
    }
    if (q) {
      params.push(`%${q}%`);
      params.push(`%${q}%`);
      where.push(`(a.full_name ILIKE $${params.length-1} OR a.email ILIKE $${params.length})`);
    }
    if (where.length) sql += ' WHERE ' + where.join(' AND ');
    sql += ' ORDER BY o.created_at DESC';
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { application_id, start_date, position, salary, content } = req.body;
    const senderId = req.user?.id || null;
    const { rows } = await getDb().query(
      'INSERT INTO offers (application_id, start_date, position, salary, content, sender_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [application_id, start_date, position || null, salary || null, content || null, senderId]
    );
    const app = await getDb().query('SELECT email, full_name, job_id FROM applications WHERE id=$1', [application_id]);
    if (app.rows[0]) {
      // Auto-create a positive result when sending an offer
      await getDb().query('INSERT INTO results(application_id, result, notes) VALUES($1,$2,$3)', [application_id, 'offer', 'Gửi thư mời nhận việc']);
    }
    if (app.rows[0]) {
      const html = content || `Xin chào ${app.rows[0].full_name},<br/>Chúng tôi trân trọng mời bạn vào vị trí ${position || ''}. Ngày bắt đầu: ${start_date}.`;
      sendEmail({ to: app.rows[0].email, subject: 'Thư mời nhận việc', html }).catch(()=>{});
    }
    // Notify recruiter poster of the job (best-effort)
    try{
      const job = await getDb().query('SELECT posted_by, title FROM jobs WHERE id=$1', [app.rows[0]?.job_id]);
      const posterId = job.rows[0]?.posted_by;
      if (posterId){
        const poster = await getDb().query('SELECT email, full_name FROM users WHERE id=$1', [posterId]);
        const to = poster.rows[0]?.email;
        if (to){
          const subject = 'Đã gửi thư offer';
          const html = `Bạn đã gửi thư mời đến ${app.rows[0].full_name} cho công việc ${job.rows[0].title}.`;
          sendEmail({ to, subject, html }).catch(()=>{});
        }
      }
    }catch(_){ /* ignore */ }
    res.status(201).json(rows[0]);
  } catch (e) { next(e); }
}

export async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await getDb().query('SELECT * FROM offers WHERE id=$1', [id]);
    if (!rows[0]) return res.status(404).json({ message: 'Offer not found' });
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function updateById(req, res, next) {
  try {
    // Offers are immutable after sending to avoid inconsistencies between parties
    return res.status(403).json({ message: 'Offer cannot be edited after sending' });
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    // Keep offers for record-keeping; prevent deletion
    return res.status(403).json({ message: 'Offer cannot be deleted' });
  } catch (e) { next(e); }
}
