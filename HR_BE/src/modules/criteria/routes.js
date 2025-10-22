import { Router } from 'express';
import { list, create, updateById, removeById } from './service.js';
import { body, param } from 'express-validator';
import { auth, requireRoles } from '../../middleware/auth.js';

const router = Router();

// Public read
router.get('/', list);

// Admin manage
router.post('/', [
  auth(), requireRoles('admin'),
  body('key').isString().notEmpty(),
  body('label').isString().notEmpty(),
  body('min').optional().isFloat(),
  body('max').optional().isFloat(),
  body('step').optional().isFloat(),
  body('active').optional().isBoolean(),
], create);

router.put('/:id', [
  auth(), requireRoles('admin'),
  param('id').isInt(),
], updateById);

router.delete('/:id', [
  auth(), requireRoles('admin'),
  param('id').isInt(),
], removeById);

export default router;
