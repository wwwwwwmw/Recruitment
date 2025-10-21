import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('application_id').isInt(),
  body('result').isString(),
  body('notes').optional().isString(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);

export default router;
