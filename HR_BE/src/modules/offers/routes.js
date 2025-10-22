import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';
import { requireRoles } from '../../middleware/auth.js';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('application_id').isInt(),
  body('start_date').isISO8601(),
  body('position').optional().isString(),
  body('salary').optional().isFloat({ min: 0 }),
  requireRoles('admin','recruiter'),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.put('/:id', [
  param('id').isInt(),
  body('start_date').optional().isISO8601(),
  body('position').optional().isString(),
  body('salary').optional().isFloat({ min: 0 }),
  body('content').optional().isString(),
  requireRoles('admin','recruiter'),
], svc.updateById);
router.delete('/:id', [param('id').isInt(), requireRoles('admin','recruiter')], svc.removeById);

export default router;
