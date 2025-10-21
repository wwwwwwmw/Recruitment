import { Router } from 'express';
import jobsRoutes from './jobs/routes.js';
import processesRoutes from './processes/routes.js';
import appsRoutes from './applications/routes.js';
import evalRoutes from './evaluations/routes.js';
import interviewsRoutes from './interviews/routes.js';
import committeesRoutes from './committees/routes.js';
import resultsRoutes from './results/routes.js';
import offersRoutes from './offers/routes.js';
import reportsRoutes from './reports/routes.js';
import authRoutes from './auth/routes.js';
import { auth, requireRoles } from '../middleware/auth.js';

const router = Router();

router.use('/auth', authRoutes);

// Public reads (jobs list) but restrict writes to recruiters/admin
router.use('/jobs', jobsRoutes);
router.use('/processes', auth(), requireRoles('admin','recruiter'), processesRoutes);
router.use('/applications', appsRoutes); // candidates can POST
router.use('/evaluations', auth(), requireRoles('admin','recruiter'), evalRoutes);
router.use('/interviews', auth(), requireRoles('admin','recruiter'), interviewsRoutes);
router.use('/committees', auth(), requireRoles('admin'), committeesRoutes);
router.use('/results', auth(), requireRoles('admin','recruiter'), resultsRoutes);
router.use('/offers', auth(), requireRoles('admin','recruiter'), offersRoutes);
router.use('/reports', auth(), requireRoles('admin','recruiter'), reportsRoutes);

export default router;
