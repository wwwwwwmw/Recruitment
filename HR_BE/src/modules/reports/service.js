import { getDb } from '../../config/db.js';

export async function summary(req, res, next) {
  try {
    const db = getDb();
    const { from, to } = req.query; // ISO date strings optional
    const range = [];
    const params = [];
    if (from){ params.push(from); range.push(`created_at >= $${params.length}`); }
    if (to){ params.push(to); range.push(`created_at <= $${params.length}`); }
    const where = range.length? (' WHERE ' + range.join(' AND ')) : '';
    const totalJobs = (await db.query('SELECT COUNT(*)::int AS n FROM jobs')).rows[0].n;
    const totalApps = (await db.query(`SELECT COUNT(*)::int AS n FROM applications${where}` , params)).rows[0].n;
    const totalOffers = (await db.query(`SELECT COUNT(*)::int AS n FROM offers${where}`, params)).rows[0].n;

    // Build result filters separately to avoid duplicating WHERE tokens
    const resultTimeConds = range.map(r => r.replaceAll('created_at', 'r.created_at'));
    const passConds = [...resultTimeConds, `lower(r.result) IN ('passed','accepted','hired','offer')`];
    const failConds = [...resultTimeConds, `lower(r.result) IN ('failed','rejected','declined')`];
    const passed = (await db.query(`SELECT COUNT(*)::int AS n FROM results r WHERE ${passConds.join(' AND ')}`, params)).rows?.[0]?.n || 0;
    const failed = (await db.query(`SELECT COUNT(*)::int AS n FROM results r WHERE ${failConds.join(' AND ')}`, params)).rows?.[0]?.n || 0;
    res.json({ totalJobs, totalApps, totalOffers, passed, failed });
  } catch (e) { next(e); }
}

export async function byJob(req, res, next) {
  try {
    const { rows } = await getDb().query(
      `SELECT j.id, j.title, COUNT(a.id)::int AS applications
       FROM jobs j LEFT JOIN applications a ON a.job_id=j.id
       GROUP BY j.id ORDER BY applications DESC`
    );
    res.json(rows);
  } catch (e) { next(e); }
}

export async function pipeline(req, res, next) {
  try {
    const { from, to } = req.query;
    const params=[]; const where=[];
    if (from){ params.push(from); where.push(`created_at >= $${params.length}`); }
    if (to){ params.push(to); where.push(`created_at <= $${params.length}`); }
    const sql = `SELECT status, COUNT(*)::int as count FROM applications ${where.length?('WHERE '+where.join(' AND ')):''} GROUP BY status`;
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function outcomes(req, res, next) {
  try {
    const { from, to } = req.query;
    const params=[]; const where=[];
    if (from){ params.push(from); where.push(`r.created_at >= $${params.length}`); }
    if (to){ params.push(to); where.push(`r.created_at <= $${params.length}`); }
    const sql = `SELECT r.result, COUNT(*)::int as count
                 FROM results r
                 ${where.length?('WHERE '+where.join(' AND ')):''}
                 GROUP BY r.result`;
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}

export async function outcomeDetail(req, res, next) {
  try {
    const { from, to } = req.query;
    const params=[]; const where=[];
    if (from){ params.push(from); where.push(`r.created_at >= $${params.length}`); }
    if (to){ params.push(to); where.push(`r.created_at <= $${params.length}`); }
    const sql = `SELECT r.id, r.result, r.notes, r.created_at, a.full_name, a.email, j.title as job_title
                 FROM results r
                 JOIN applications a ON a.id=r.application_id
                 JOIN jobs j ON j.id=a.job_id
                 ${where.length?('WHERE '+where.join(' AND ')):''}
                 ORDER BY r.created_at DESC`;
    const { rows } = await getDb().query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
}
