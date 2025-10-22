import { getDb } from '../../config/db.js';
import { sendEmail } from '../../utils/email.js';

export async function list(req, res, next) {
  try {
    const { rows } = await getDb().query('SELECT * FROM evaluations ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) { next(e); }
}

export async function screening(req, res, next){
  try{
    const db = getDb();
    const { job_id } = req.query;
    if (!job_id) return res.status(400).json({ message: 'job_id is required' });
    // Load job and requirements
    const jobQ = await db.query('SELECT id, title, posted_by, requirements FROM jobs WHERE id=$1', [job_id]);
    const job = jobQ.rows[0];
    if (!job) return res.status(404).json({ message: 'Job not found' });
    // Recruiter scope: must own this job
    if (req.user?.role === 'recruiter' && job.posted_by !== req.user.id){
      return res.status(403).json({ message: 'Không có quyền xem sàng lọc cho công việc này' });
    }
    const reqs = job.requirements || {};
    const criteria = Object.entries((reqs.scores || {})).map(([key, cfg])=>({ key, ...(cfg||{}) }));

    // Fetch applications for this job with candidate user id if exists and profile
    const apps = await db.query(`
      SELECT a.*, u.id as user_id, cp.scores as profile_scores
      FROM applications a
      LEFT JOIN users u ON lower(u.email)=lower(a.email)
      LEFT JOIN candidate_profiles cp ON cp.user_id=u.id
      WHERE a.job_id=$1
      ORDER BY a.created_at DESC
    `, [job_id]);

    const results = apps.rows.map(a=>{
      const scores = (a.profile_scores || {});
      let satisfied = 0; let total = 0; let failImportant = false;
      let ratioSum = 0; let ratioCount = 0;
      for (const c of criteria){
        total++;
        const min = (c.min ?? 0);
        const val = typeof scores[c.key] === 'number' ? scores[c.key] : null;
        const ok = (val!=null && val >= min);
        if (ok) satisfied++; else if (c.important) failImportant = true;
        if (min > 0){
          const v = (typeof val === 'number') ? val : 0;
          ratioSum += (v / min);
          ratioCount += 1;
        }
      }
      const ratioPercent = ratioCount ? Math.round((ratioSum / ratioCount) * 100) : 0;
      const percent = ratioPercent; // ratio-based percent as requested
      const status = (!total) ? 'chưa đặt yêu cầu' : (failImportant || satisfied<total) ? `đạt ${percent}% yêu cầu` : 'đạt yêu cầu';
      return {
        application_id: a.id,
        full_name: a.full_name,
        email: a.email,
        status,
        percent,
        scores, // include scores so FE can compute if needed
        created_at: a.created_at,
      };
    });

    // Sort by percent desc then created_at asc
    results.sort((x,y)=> y.percent - x.percent || new Date(x.created_at) - new Date(y.created_at));
    res.json({ job: { id: job.id, title: job.title, requirements: job.requirements }, results });
  }catch(e){ next(e); }
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
