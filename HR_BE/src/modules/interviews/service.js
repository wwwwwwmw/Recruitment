import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';
import { createNotification } from '../notifications/service.js';
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

    const db = getDb();
    const { rows } = await db.query(
      'INSERT INTO interviews (application_id, scheduled_at, location, mode) VALUES ($1,$2,$3,$4) RETURNING *',
      [application_id, scheduled_at, location || null, mode || null]
    );

    // Fire-and-forget email notification
    sendEmail({
      to: app.rows[0].email,
      subject: 'Interview Scheduled',
      text: `Hi ${app.rows[0].full_name}, your interview is scheduled at ${scheduled_at}.`
    }).catch(() => {});

    // Notifications on create (legacy schema)
    try{
      const u = await db.query('SELECT id FROM users WHERE lower(email)=lower($1) LIMIT 1', [app.rows[0].email]);
      const candidateId = u.rows?.[0]?.id;
      const job = await db.query('SELECT title FROM jobs WHERE id=(SELECT job_id FROM applications WHERE id=$1)', [application_id]);
      const jobTitle = job.rows?.[0]?.title || '';
      const title = 'Lịch phỏng vấn mới';
      const message = `Công việc: ${jobTitle} - Thời gian: ${scheduled_at} - Địa điểm: ${location || ''} - Hình thức: ${mode || 'offline'}`;
      if (candidateId) await createNotification(candidateId, { title, message, type: 'interview.created', relatedType: 'interview', relatedId: rows[0].id });
      if (req.user?.id) await createNotification(req.user.id, { title: 'Bạn đã tạo lịch phỏng vấn', message: `Ứng tuyển #${application_id}: ${scheduled_at}`, type: 'interview.created', relatedType: 'interview', relatedId: rows[0].id });
    }catch(_){ /* ignore */ }

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
    const db = getDb();
    const before = await db.query('SELECT * FROM interviews WHERE id=$1', [id]);
    if (!before.rows[0]) return res.status(404).json({ message: 'Interview not found' });
    const { rows } = await db.query(`UPDATE interviews SET ${updates.join(',')}, updated_at=now() WHERE id=$${values.length} RETURNING *`, values);
    const updated = rows[0];

    // Notify candidate and actor
    try {
      const app = await db.query('SELECT id, email, full_name FROM applications WHERE id=$1', [updated.application_id]);
      const email = app.rows[0]?.email;
      const fullName = app.rows[0]?.full_name || '';
      // email (best-effort)
      if (email) {
        sendEmail({ to: email, subject: 'Lịch phỏng vấn đã thay đổi', text: `Xin chào ${fullName}, lịch phỏng vấn của bạn đã được cập nhật: ${updated.scheduled_at} (${updated.mode || 'trực tiếp'}) tại ${updated.location || ''}` }).catch(()=>{});
      }
      // notifications (best-effort)
      const u = await db.query('SELECT id FROM users WHERE lower(email)=lower($1)', [email]);
      const candidateId = u.rows[0]?.id;
      if (candidateId) await createNotification(candidateId, { title: 'Lịch phỏng vấn đã thay đổi', message: `Ứng tuyển #${updated.application_id}: ${updated.scheduled_at}`, type: 'interview.updated', relatedType: 'interview', relatedId: updated.id });
      if (req.user?.id) {
        await createNotification(req.user.id, { title: 'Bạn đã cập nhật lịch phỏng vấn', message: `Ứng tuyển #${updated.application_id}: ${updated.scheduled_at}`, type: 'interview.updated', relatedType: 'interview', relatedId: updated.id });
        // email to recruiter (optional)
        try {
          const me = await db.query('SELECT email, full_name FROM users WHERE id=$1', [req.user.id]);
          const rEmail = me.rows[0]?.email;
          if (rEmail) sendEmail({ to: rEmail, subject: 'Bạn đã cập nhật lịch phỏng vấn', text: `Bạn vừa cập nhật lịch cho ứng tuyển #${updated.application_id}: ${updated.scheduled_at}` }).catch(()=>{});
        } catch {}
      }
    } catch {}

    res.json(updated);
  } catch (e) { next(e); }
}

export async function removeById(req, res, next) {
  try {
    const { id } = req.params;
    const db = getDb();
    const itv = await db.query('SELECT * FROM interviews WHERE id=$1', [id]);
    if (!itv.rows[0]) return res.json({ success: true });
    const row = itv.rows[0];
    await db.query('DELETE FROM interviews WHERE id=$1', [id]);

    // Notify cancellation
    try {
      const app = await db.query('SELECT id, email, full_name FROM applications WHERE id=$1', [row.application_id]);
      const email = app.rows[0]?.email;
      const fullName = app.rows[0]?.full_name || '';
      if (email) {
        sendEmail({ to: email, subject: 'Lịch phỏng vấn đã hủy', text: `Xin chào ${fullName}, lịch phỏng vấn của bạn vào ${row.scheduled_at} đã bị hủy.` }).catch(()=>{});
      }
      const u = await db.query('SELECT id FROM users WHERE lower(email)=lower($1)', [email]);
      const candidateId = u.rows[0]?.id;
      if (candidateId) await createNotification(candidateId, { title: 'Lịch phỏng vấn đã hủy', message: `Ứng tuyển #${row.application_id} đã hủy lịch vào ${row.scheduled_at}`, type: 'interview.canceled', relatedType: 'interview', relatedId: row.id });
      if (req.user?.id) {
        await createNotification(req.user.id, { title: 'Bạn đã hủy lịch phỏng vấn', message: `Ứng tuyển #${row.application_id}: ${row.scheduled_at}`, type: 'interview.canceled', relatedType: 'interview', relatedId: row.id });
        try {
          const me = await db.query('SELECT email, full_name FROM users WHERE id=$1', [req.user.id]);
          const rEmail = me.rows[0]?.email;
          if (rEmail) sendEmail({ to: rEmail, subject: 'Bạn đã hủy lịch phỏng vấn', text: `Bạn vừa hủy lịch phỏng vấn của ứng tuyển #${row.application_id}: ${row.scheduled_at}` }).catch(()=>{});
        } catch {}
      }
    } catch {}

    res.json({ success: true });
  } catch (e) { next(e); }
}
