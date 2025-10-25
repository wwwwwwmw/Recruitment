import { Router } from 'express';
import * as svc from './service.js';

const router = Router();

router.get('/summary', svc.summary);
router.get('/by-job', svc.byJob);
router.get('/pipeline', svc.pipeline);
router.get('/outcomes', svc.outcomes);
router.get('/outcome-detail', svc.outcomeDetail);

export default router;

/**
 * @openapi
 * tags:
 *   - name: Báo cáo
 *     description: Các báo cáo thống kê liên quan đến tuyển dụng
 */

/**
 * @openapi
 * /api/reports/summary:
 *   get:
 *     tags: [Báo cáo]
 *     summary: Báo cáo tổng quan
 */
