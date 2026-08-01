import { Router } from 'express';
import { protect, requireRole } from '../middleware/auth.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import {
  payContributionSchema,
  bulkContributionSchema,
  manualContributionSchema,
} from '../validators/contribution.validator.js';
import {
  payContribution,
  getContributions,
  getContributionById,
  getPendingContributions,
  getOverdueContributions,
  getContributionStats,
  getGroupContributions,
  updateContribution,
  deleteContribution,
  bulkContributions,
  manualContribution,
} from '../controllers/contributions.controller.js';

const router = Router();

// All routes require a valid JWT
router.use(protect);

// ---- Member routes ----
router.post('/', validate(payContributionSchema), payContribution);   // pay own contribution
router.get('/', getContributions);                                     // list with filters
router.get('/pending', getPendingContributions);                       // unpaid across all groups
router.get('/overdue', getOverdueContributions);                       // overdue across all groups
router.get('/stats', getContributionStats);                            // on-time rate & counts

// ---- Group-scoped (any active member) ----
// NOTE: mounted on contributions router — group param handled in controller
// Main group route is registered in app.js as /groups/:id/contributions

// ---- Admin routes ----
router.post('/bulk', requireRole('system_admin'), validate(bulkContributionSchema), bulkContributions);
router.post('/manual', requireRole('system_admin'), validate(manualContributionSchema), manualContribution);

// ---- Single-resource routes (must come after named paths) ----
router.get('/:id', getContributionById);
router.put('/:id', requireRole('system_admin'), updateContribution);
router.delete('/:id', requireRole('system_admin'), deleteContribution);

export default router;
