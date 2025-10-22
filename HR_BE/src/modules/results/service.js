import { getDb } from '../../config/db.js';

export async function list(req, res, next) {
  try {
    const { mine, job_id, q } = req.query;
  let sql = 'SELECT r.*, a.full_name, a.email, a.job_id, j.title as job_title FROM results r JOIN applications a ON a.id=r.application_id JOIN jobs j ON j.id=a.job_id';
    const params = [];
    const where = [];
    // jobs already joined above
    if (req.user && req.user.role === 'candidate' && mine === 'true') {
      params.push(req.user.email);
      where.push(`a.email=$${params.length}`);
    }
    if (req.user && req.user.role === 'recruiter' && mine === 'true') {
      params.push(req.user.id);
      where.push(`j.posted_by=$${params.length}`);
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
    sql += ' ORDER BY r.created_at DESC';
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    const { application_id, result, notes } = req.body;
    const { rows } = await getDb().query('INSERT INTO results (application_id, result, notes) VALUES ($1,$2,$3) RETURNING *', [application_id, result, notes || null]);
    // Auto create and send an offer when approving
    if (['passed','accepted','hired','offer'].includes((result||'').toLowerCase())){
      const offer = req.body.offer || {};
      const startDate = offer.start_date || new Date();
      const position = offer.position || null;
      const salary = offer.salary || null;
      // Fetch application details for email
      const app = await getDb().query('SELECT full_name, email FROM applications WHERE id=$1', [application_id]);
      const fullName = app.rows?.[0]?.full_name || '';
      const toEmail = app.rows?.[0]?.email || '';
      const html = offer.content || `Xin chào ${fullName},<br/>Chúc mừng bạn đã vượt qua vòng tuyển dụng. Đây là thư mời nhận việc.`;
      await getDb().query('INSERT INTO offers (application_id, start_date, position, salary, content) VALUES ($1, $2, $3, $4, $5)', [application_id, startDate, position, salary, html]);
      // Send email now
      try { await (await import('../../utils/email.js')).sendEmail({ to: toEmail, subject: 'Thư mời nhận việc', html }); } catch {}
    }
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

export async function updateById(req, res, next) {
  try {
    const { id } = req.params;
    const fields = ['result','notes'];
    const updates=[]; const values=[];
    for (const f of fields) if (req.body[f]!==undefined){ updates.push(`${f}=$${updates.length+1}`); values.push(req.body[f]); }
    if (!updates.length) return res.json({ message: 'No changes' });
    values.push(id);
    const { rows } = await getDb().query(`UPDATE results SET ${updates.join(',')}, updated_at=now() WHERE id=$${values.length} RETURNING *`, values);
    res.json(rows[0]);
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    const { id } = req.params;
    await getDb().query('DELETE FROM results WHERE id=$1', [id]);
    res.json({ success: true });
  } catch (e) { next(e); }
}
