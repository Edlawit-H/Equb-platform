import { Router } from 'express';
import { protect, requireRole } from '../middleware/auth.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { payContributionSchema, bulkContributionSchema, manualContributionSchema } from '../validators/contribution.validator.js';
import {
  payContribution,
  getContributions,
  getContributionById,
  getPendingContributions,
  getOverdueContributions,
  getContributionStats,
  updateContribution,
  deleteContribution,
  bulkContributions,
  manualContribution,
} from '../controllers/contributions.controller.js';

const router = Router();
router.use(protect);

router.post('/', validate(payContributionSchema), payContribution);
router.get('/', getContributions);
router.get('/pending', getPendingContributions);
router.get('/overdue', getOverdueContributions);
router.get('/stats', getContributionStats);
router.post('/bulk', requireRole('system_admin'), validate(bulkContributionSchema), bulkContributions);
router.post('/manual', requireRole('system_admin'), validate(manualContributionSchema), manualContribution);
router.get('/:id', getContributionById);
router.put('/:id', requireRole('system_admin'), updateContribution);
router.delete('/:id', requireRole('system_admin'), deleteContribution);

export default router;