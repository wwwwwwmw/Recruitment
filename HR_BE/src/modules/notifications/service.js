import { getDb } from '../../config/db.js';

export async function listMine(req, res, next){
  try{
    const uid = req.user?.id;
    const role = req.user?.role;
    if(!uid) return res.status(401).json({ message: 'Unauthorized' });

    // Admin can view all notifications unless explicitly requesting mine=true
    if (role === 'admin' && req.query.mine !== 'true') {
      const { rows } = await getDb().query(
        `SELECT n.*,
                su.full_name AS sender_name, su.email AS sender_email,
                ru.full_name AS recipient_name, ru.email AS recipient_email
           FROM notifications n
           LEFT JOIN users su ON su.id = n.sender_id
           LEFT JOIN users ru ON ru.id = n.recipient_id
          ORDER BY n.created_at DESC`
      );
      return res.json(rows);
    }

    const { rows } = await getDb().query(
      `SELECT n.*, 
              su.full_name AS sender_name, su.email AS sender_email,
              ru.full_name AS recipient_name, ru.email AS recipient_email
         FROM notifications n
         LEFT JOIN users su ON su.id = n.sender_id
         LEFT JOIN users ru ON ru.id = n.recipient_id
        WHERE (n.recipient_id = $1 OR n.user_id = $1)
        ORDER BY n.created_at DESC`,
      [uid]
    );
    res.json(rows);
  }catch(e){ next(e); }
}

export async function markRead(req, res, next){
  try{
    const uid = req.user?.id;
    if(!uid) return res.status(401).json({ message: 'Unauthorized' });
    const { id } = req.params;
    await getDb().query('UPDATE notifications SET is_read=true WHERE id=$1 AND user_id=$2', [id, uid]);
    res.json({ ok: true });
  }catch(e){ next(e); }
}

export async function createNotification(userId, { title, message, type, relatedType, relatedId }){
  try{
    await getDb().query(
      'INSERT INTO notifications(user_id, title, message, type, related_type, related_id) VALUES ($1,$2,$3,$4,$5,$6)',
      [userId, title, message || null, type || null, relatedType || null, relatedId || null]
    );
  }catch{/* ignore */}
}

// Backward/forward compatible creator that works with both legacy and enriched schemas
export async function createNotificationFlexible({ senderId = null, recipientId = null, title, message, applicationId = null, interviewId = null, offerId = null, type = null, relatedType = null, relatedId = null }){
  // Try enriched schema first (sender/recipient/application refs). Fallback to legacy user_id if columns missing.
  try{
    await getDb().query(
      `INSERT INTO notifications(sender_id, recipient_id, application_id, interview_id, offer_id, title, message, type, related_type, related_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [senderId, recipientId, applicationId, interviewId, offerId, title, message || null, type || null, relatedType || null, relatedId || null]
    );
  }catch(_e){
    try{
      const userId = recipientId || senderId;
      await createNotification(userId, { title, message, type, relatedType, relatedId });
    }catch(_e2){ /* ignore */ }
  }
}
