import { Router } from 'express';
import { body } from 'express-validator';
import * as svc from './service.js';
import { auth, requireRoles } from '../../middleware/auth.js';

const router = Router();

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
