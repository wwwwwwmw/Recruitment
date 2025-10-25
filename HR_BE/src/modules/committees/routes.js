import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('name').isString().notEmpty(),
  body('description').optional().isString(),
], svc.create);

router.post('/:id/members', [param('id').isInt(), body('user_id').isInt()], svc.addMember);
router.get('/:id', [param('id').isInt()], svc.getById);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Hội đồng tuyển dụng
 *     description: Quản lý hội đồng tuyển dụng và thành viên
 */

/**
 * @openapi
 * /api/committees:
 *   get:
 *     tags: [Hội đồng tuyển dụng]
 *     summary: Lấy danh sách hội đồng
 *   post:
 *     tags: [Hội đồng tuyển dụng]
 *     summary: Tạo hội đồng mới
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 */
