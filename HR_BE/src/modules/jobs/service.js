import slugify from 'slugify';
import { getDb } from '../../config/db.js';

async function ensureRequirementsColumn(){
  await getDb().query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS requirements JSONB');
}

async function ensureStatusColumn(){
  await getDb().query("ALTER TABLE jobs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'open'");
}

export async function list(req, res, next) {
  try {
    await ensureStatusColumn();
    const mine = req.query.mine === 'true';
    const q = req.query.q;
    let sql = 'SELECT * FROM jobs';
    const where = [];
    const params = [];
    if (mine && req.user && (req.user.role === 'admin' || req.user.role === 'recruiter')) {
      params.push(req.user.id);
      where.push(`posted_by=$${params.length}`);
    }
    if (q) {
      params.push(`%${q}%`);
      params.push(`%${q}%`);
      params.push(`%${q}%`);
      where.push(`(title ILIKE $${params.length-2} OR department ILIKE $${params.length-1} OR location ILIKE $${params.length})`);
    }
    if (where.length) sql += ' WHERE ' + where.join(' AND ');
    sql += ' ORDER BY created_at DESC';
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function create(req, res, next) {
  try {
    await ensureRequirementsColumn();
    await ensureStatusColumn();
    const { title, slug, description, department, location, requirements } = req.body;
    const s = slug || slugify(title, { lower: true, strict: true });
    const postedBy = req.user?.id || null;
    const { rows } = await getDb().query(
      "INSERT INTO jobs (title, slug, description, department, location, posted_by, requirements, status) VALUES ($1,$2,$3,$4,$5,$6,$7,'open') RETURNING *",
      [title, s, description, department || null, location || null, postedBy, requirements || null]
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
    await ensureRequirementsColumn();
    await ensureStatusColumn();
    const { id } = req.params;
    const fields = ['title','slug','description','department','location','requirements','status'];
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

export async function closeJob(req, res, next){
  try{
    await ensureStatusColumn();
    const { id } = req.params;
    // Only admin can close any; recruiter can close their own
    if (req.user?.role === 'recruiter'){
      const { rowCount } = await getDb().query("UPDATE jobs SET status='closed', updated_at=now() WHERE id=$1 AND posted_by=$2", [id, req.user.id]);
      if (!rowCount) return res.status(403).json({ message: 'Bạn chỉ có thể kết thúc công việc do bạn đăng' });
    } else {
      await getDb().query("UPDATE jobs SET status='closed', updated_at=now() WHERE id=$1", [id]);
    }
    // Bulk reject all pending applications for this job and send rejection emails
    const active = ['submitted','screening','interviewed'];
    const apps = await getDb().query("SELECT id, email, full_name FROM applications WHERE job_id=$1 AND status = ANY($2)", [id, active]);
    await getDb().query("UPDATE applications SET status='rejected', updated_at=now() WHERE job_id=$1 AND status = ANY($2)", [id, active]);
    // Create a result row for each rejected application if not exists
    for (const a of apps.rows){
      const exists = await getDb().query('SELECT 1 FROM results WHERE application_id=$1 LIMIT 1', [a.id]);
      if (!exists.rowCount){
        await getDb().query("INSERT INTO results(application_id, result, notes) VALUES($1,$2,$3)", [a.id, 'rejected', 'Công việc đã kết thúc']);
      }
    }
    // Fetch job title for email
    const job = await getDb().query('SELECT title FROM jobs WHERE id=$1', [id]);
    const title = job.rows[0]?.title || '';
    for (const a of apps.rows){
      const html = `Xin chào ${a.full_name},<br/>Rất tiếc bạn chưa được chọn cho vị trí ${title}. Cảm ơn bạn đã quan tâm.`;
      try{ await import('../../utils/email.js').then(m=> m.sendEmail({ to: a.email, subject: 'Kết quả tuyển dụng', html })); }catch(_){ /* best-effort */ }
    }
    res.json({ ok: true });
  }catch(e){ next(e); }
}
