import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

router.get('/', svc.list);
router.post('/', [
  body('name').isString().notEmpty(),
  body('description').optional().isString(),
], svc.create);

router.post('/:id/members', [param('id').isInt(), body('user_id').isInt()], svc.addMember);
router.get('/:id', [param('id').isInt()], svc.getById);

export default router;
