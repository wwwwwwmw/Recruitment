import { Router } from 'express';
import * as jobs from './service.js';
import { body, param } from 'express-validator';
import { auth, requireRoles } from '../../middleware/auth.js';

const router = Router();

// Parse JWT if present so list can honor mine=true for recruiters
router.get('/', auth(false), jobs.list);
router.post('/', [
  body('title').isString().notEmpty(),
  body('slug').optional().isString(),
  body('description').isString().notEmpty(),
  body('department').optional().isString(),
  body('location').optional().isString(),
], auth(), requireRoles('admin','recruiter'), jobs.create);

router.get('/:id', [param('id').isInt()], jobs.getById);
router.put('/:id', [param('id').isInt()], auth(), requireRoles('admin','recruiter'), jobs.updateById);
router.delete('/:id', [param('id').isInt()], auth(), requireRoles('admin','recruiter'), jobs.removeById);
router.post('/:id/close', [param('id').isInt()], auth(), requireRoles('admin','recruiter'), jobs.closeJob);

export default router;
