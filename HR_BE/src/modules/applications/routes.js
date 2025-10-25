import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';
import { auth } from '../../middleware/auth.js';

const router = Router();

// Candidate applies to a job
// Parse JWT if present so list can honor mine=true for recruiters/candidates
router.get('/', auth(false), svc.list);
/**
 * @openapi
 * tags:
 *   - name: Hồ sơ ứng tuyển
 *     description: Hồ sơ ứng viên nộp cho các vị trí
 */

/**
 * @openapi
 * /api/applications:
 *   get:
 *     tags: [Hồ sơ ứng tuyển]
 *     summary: Lấy danh sách hồ sơ ứng tuyển (có parse JWT nếu có)
 *     responses:
 *       '200':
 *         description: Thành công
 *   post:
 *     tags: [Hồ sơ ứng tuyển]
 *     summary: Tạo hồ sơ ứng tuyển mới (ứng viên)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               job_id:
 *                 type: integer
 *                 description: ID công việc
 *               full_name:
 *                 type: string
 *                 description: Họ tên ứng viên
 *               email:
 *                 type: string
 *                 description: Email ứng viên
 *     responses:
 *       '201':
 *         description: Tạo thành công
 */
router.post('/', [
  body('job_id').isInt(),
  body('full_name').isString().notEmpty(),
  body('email').isEmail(),
  body('phone').optional().isString(),
  body('resume_url').optional().isString(),
  body('cover_letter').optional().isString(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.patch('/:id/status', [param('id').isInt(), body('status').isString()], svc.updateStatus);

export default router;
