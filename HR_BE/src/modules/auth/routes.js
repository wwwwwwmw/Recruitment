import { Router } from 'express';
import { body } from 'express-validator';
import * as svc from './service.js';
import { auth, requireRoles } from '../../middleware/auth.js';

const router = Router();

/**
 * @openapi
 * tags:
 *   - name: Xác thực
 *     description: Các endpoint liên quan đến xác thực (đăng ký, đăng nhập, đăng xuất)
 */

/**
 * @openapi
 * /api/auth/register:
 *   post:
 *     tags: [Xác thực]
 *     summary: Đăng ký tài khoản ứng viên
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
 *                 description: Email người dùng
 *               password:
 *                 type: string
 *                 description: Mật khẩu (ít nhất 6 ký tự)
 *     responses:
 *       '201':
 *         description: Tạo thành công
 */

/**
 * @openapi
 * /api/auth/register-admin:
 *   post:
 *     tags: [Xác thực]
 *     summary: Admin tạo tài khoản recruiter/admin
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       '201':
 *         description: Tạo thành công
 */

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     tags: [Xác thực]
 *     summary: Đăng nhập
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       '200':
 *         description: Đăng nhập thành công (trả về token)
 */

/**
 * @openapi
 * /api/auth/me:
 *   get:
 *     tags: [Xác thực]
 *     summary: Lấy thông tin người dùng hiện tại
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       '200':
 *         description: Thông tin người dùng
 */

// Candidate self-register
router.post('/register', [
  body('full_name').isString().notEmpty(),
  body('email').isEmail(),
  body('password').isString().isLength({ min: 6 })
], svc.registerCandidate);

// Admin can create recruiter/admin accounts
router.post('/register-admin', auth(), requireRoles('admin'), [
  body('full_name').isString().notEmpty(),
  body('email').isEmail(),
  body('password').isString().isLength({ min: 6 }),
  body('role').isIn(['admin','recruiter'])
], svc.registerByAdmin);

router.post('/login', [
  body('email').isEmail(),
  body('password').isString()
], svc.login);

router.get('/me', auth(), svc.me);
router.post('/logout', auth(), svc.logout);

export default router;
