import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';
import { requireRoles } from '../../middleware/auth.js';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('application_id').isInt(),
  body('result').isString(),
  body('notes').optional().isString(),
  requireRoles('admin','recruiter'),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);

router.put('/:id', [
  param('id').isInt(),
  body('result').optional().isString(),
  body('notes').optional().isString(),
  requireRoles('admin','recruiter'),
], svc.updateById);

router.delete('/:id', [param('id').isInt(), requireRoles('admin','recruiter')], svc.removeById);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Kết quả tuyển dụng
 *     description: Lưu trữ kết quả phỏng vấn/sàng lọc và ghi chú
 */

/**
 * @openapi
 * /api/results:
 *   get:
 *     tags: [Kết quả tuyển dụng]
 *     summary: Lấy danh sách kết quả
 *   post:
 *     tags: [Kết quả tuyển dụng]
 *     summary: Tạo một kết quả mới (admin/recruiter)
 */
