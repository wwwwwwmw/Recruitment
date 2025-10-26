import { Router } from 'express';
import { listMine, markRead } from './service.js';
import { param } from 'express-validator';

const router = Router();

// All routes here require auth() from parent router
router.get('/', listMine);
router.put('/:id/read', [param('id').isInt()], markRead);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Thông báo
 *     description: Thông báo hệ thống cho người dùng
 *
 * /api/notifications:
 *   get:
 *     tags: [Thông báo]
 *     summary: Lấy danh sách thông báo của tôi
 * /api/notifications/{id}/read:
 *   put:
 *     tags: [Thông báo]
 *     summary: Đánh dấu thông báo đã đọc
 */
