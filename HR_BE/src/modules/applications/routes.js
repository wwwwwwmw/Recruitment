import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

// Candidate applies to a job
router.get('/', svc.list);
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
