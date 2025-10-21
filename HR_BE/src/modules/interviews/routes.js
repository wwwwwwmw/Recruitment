import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('application_id').isInt(),
  body('scheduled_at').isISO8601(),
  body('location').optional().isString(),
  body('mode').optional().isString(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.patch('/:id', [param('id').isInt()], svc.updateById);

export default router;
