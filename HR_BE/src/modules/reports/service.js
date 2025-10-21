import { getDb } from '../../config/db.js';

export async function summary(req, res, next) {
  try {
    const db = getDb();
    const totalJobs = (await db.query('SELECT COUNT(*)::int AS n FROM jobs')).rows[0].n;
    const totalApps = (await db.query('SELECT COUNT(*)::int AS n FROM applications')).rows[0].n;
    const totalOffers = (await db.query('SELECT COUNT(*)::int AS n FROM offers')).rows[0].n;
    const hired = (await db.query("SELECT COUNT(*)::int AS n FROM applications WHERE status='hired'"))?.rows?.[0]?.n || 0;
    res.json({ totalJobs, totalApps, totalOffers, hired });
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
    const { rows } = await getDb().query(
      `SELECT status, COUNT(*)::int as count FROM applications GROUP BY status`
    );
    res.json(rows);
  } catch (e) { next(e); }
}
