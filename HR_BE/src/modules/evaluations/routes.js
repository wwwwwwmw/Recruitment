import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

// Screening and evaluation
router.get('/', svc.list);
router.get('/screening', svc.screening);
router.post('/', [
  body('application_id').isInt(),
  body('stage_id').optional().isInt(),
  body('score').isFloat({ min: 0, max: 100 }),
  body('comments').optional().isString(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Đánh giá
 *     description: Các endpoint liên quan tới việc đánh giá hồ sơ và sàng lọc
 */

/**
 * @openapi
 * /api/evaluations:
 *   get:
 *     tags: [Đánh giá]
 *     summary: Lấy danh sách đánh giá
 *   post:
 *     tags: [Đánh giá]
 *     summary: Tạo đánh giá mới (admin/recruiter)
 */
