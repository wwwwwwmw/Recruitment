import { Router } from 'express';
import * as svc from './service.js';
import { body, param, validationResult } from 'express-validator';
import { requireRoles } from '../../middleware/auth.js';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('application_id').isInt(),
  body('scheduled_at').isISO8601(),
  body('location').optional().isString(),
  body('mode').optional().isString(),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ message: 'Invalid input', errors: errors.array() });
    next();
  },
  requireRoles('admin','recruiter'),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.patch('/:id', [param('id').isInt(), requireRoles('admin','recruiter')], svc.updateById);
router.delete('/:id', [param('id').isInt(), requireRoles('admin','recruiter')], svc.removeById);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Phỏng vấn
 *     description: Lịch phỏng vấn và quản lý buổi phỏng vấn
 */

/**
 * @openapi
 * /api/interviews:
 *   get:
 *     tags: [Phỏng vấn]
 *     summary: Lấy lịch phỏng vấn
 *   post:
 *     tags: [Phỏng vấn]
 *     summary: Tạo lịch phỏng vấn mới (admin/recruiter)
 */
