import { Router } from 'express';
import { getMine, putMine, getByEmail } from './service.js';
import { auth } from '../../middleware/auth.js';
import { query } from 'express-validator';

const router = Router();

// Candidate self profile
router.get('/me', auth(), getMine);
router.put('/me', auth(), putMine);

// Admin/Recruiter: fetch candidate profile by email
router.get('/by-email', [auth(), query('email').isEmail()], getByEmail);

export default router;
