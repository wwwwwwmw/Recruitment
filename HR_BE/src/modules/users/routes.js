import { Router } from 'express';
import { body, param } from 'express-validator';
import { auth, requireRoles } from '../../middleware/auth.js';
import * as svc from './service.js';

const router = Router();

// Public summary (authenticated) so candidates can see poster name/email
router.get('/:id/summary', [auth(), param('id').isInt()], svc.getSummary);

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
