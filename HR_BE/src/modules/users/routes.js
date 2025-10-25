import { Router } from 'express';
import { body, param } from 'express-validator';
import { auth, requireRoles } from '../../middleware/auth.js';
import * as svc from './service.js';

const router = Router();

// Public summary (authenticated) so candidates can see poster name/email
router.get('/:id/summary', [auth(), param('id').isInt()], svc.getSummary);

/**
 * @openapi
 * tags:
 *   - name: Người dùng
 *     description: Quản lý người dùng (admin)
 */

/**
 * @openapi
 * /api/users:
 *   get:
 *     tags: [Người dùng]
 *     summary: Lấy danh sách người dùng (admin)
 *     responses:
 *       '200':
 *         description: Thành công
 *   post:
 *     tags: [Người dùng]
 *     summary: Tạo người dùng mới (admin)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               full_name:
 *                 type: string
 *                 description: Họ và tên
 *               email:
 *                 type: string
 *                 description: Email
 *               role:
 *                 type: string
 *                 description: Vai trò (admin/recruiter/...)
 *               password:
 *                 type: string
 *                 description: Mật khẩu
 *     responses:
 *       '201':
 *         description: Tạo thành công
 */

// Admin-only access
router.use(auth(), requireRoles('admin'));

router.get('/', svc.list);
router.get('/:id', svc.getById);

router.post(
  '/',
  [
    body('full_name').isString().trim().notEmpty(),
    body('email').isEmail().normalizeEmail(),
    body('role').optional().isString(),
    body('password').optional().isString().isLength({ min: 6 }),
  ],
  svc.create
);

router.put(
  '/:id',
  [
    param('id').isInt(),
    body('full_name').optional().isString().trim().notEmpty(),
    body('email').optional().isEmail().normalizeEmail(),
    body('role').optional().isString(),
    body('password').optional().isString().isLength({ min: 6 }),
  ],
  svc.update
);

router.delete('/:id', [param('id').isInt()], svc.remove);

router.post('/:id/reset-password', [param('id').isInt(), body('password').isLength({ min: 6 })], svc.resetPassword);

export default router;
