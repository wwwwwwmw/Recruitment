import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';
import { auth } from '../../middleware/auth.js';

const router = Router();

// Candidate applies to a job
// Parse JWT if present so list can honor mine=true for recruiters/candidates
router.get('/', auth(false), svc.list);
router.post('/', [
  body('job_id').isInt(),
  body('full_name').isString().notEmpty(),
  body('email').isEmail(),
  body('phone').optional().isString(),
  body('resume_url').optional().isString(),
  body('cover_letter').optional().isString(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.patch('/:id/status', [param('id').isInt(), body('status').isString()], svc.updateStatus);

export default router;
