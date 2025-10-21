import { Router } from 'express';
import * as svc from './service.js';
import { body, param } from 'express-validator';

const router = Router();

// Define a recruitment process with stages
router.get('/', svc.list);
router.post('/', [
  body('name').isString().notEmpty(),
  body('stages').isArray().notEmpty(),
], svc.create);

router.get('/:id', [param('id').isInt()], svc.getById);
router.put('/:id', [param('id').isInt()], svc.updateById);
router.delete('/:id', [param('id').isInt()], svc.removeById);

export default router;
