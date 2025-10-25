import { Router } from 'express';
import { getMine, putMine, getByEmail } from './service.js';
import { auth } from '../../middleware/auth.js';
import { query } from 'express-validator';

const router = Router();

// Candidate self profile
router.get('/me', auth(), getMine);
router.put('/me', auth(), putMine);

// Admin/Recruiter: fetch candidate profile by email
router.get('/by-email', [auth(), query('email').isEmail()], getByEmail);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Hồ sơ ứng viên
 *     description: Thông tin hồ sơ ứng viên (self-service và admin truy vấn)
 */

/**
 * @openapi
 * /api/profiles/me:
 *   get:
 *     tags: [Hồ sơ ứng viên]
 *     summary: Lấy hồ sơ của người dùng hiện tại
 *     security:
 *       - bearerAuth: []
 */
