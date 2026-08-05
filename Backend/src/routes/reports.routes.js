import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import {
  getDashboard,
  getUserSummary,
  getGroupSummary,
  getContributionsReport,
  getPayoutsReport,
  getFinancialOverview,
  getAnalytics,
  exportPdf,
  exportExcel,
} from '../controllers/reports.controller.js';

const router = Router();

// All routes require authentication
router.use(protect);

router.get('/dashboard', getDashboard);
router.get('/user-summary', getUserSummary);
router.get('/group-summary', getGroupSummary);
router.get('/contributions', getContributionsReport);
router.get('/payouts', getPayoutsReport);
router.get('/financial', getFinancialOverview);
router.get('/analytics', getAnalytics);
router.get('/export/pdf', exportPdf);
router.get('/export/excel', exportExcel);

export default router;
