import { Router } from 'express';
import { protect, requireRole } from '../middleware/auth.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { payoutFilterSchema, updatePayoutSchema } from '../validators/payout.validator.js';
import {
  getMyPayouts,
  getPayoutHistory,
  getPayoutSchedule,
  getPayoutById,
  approvePayout,
  rejectPayout,
  updatePayout,
  deletePayout,
} from '../controllers/payouts.controller.js';

const router = Router();

// All routes require authentication
router.use(protect);

// User payout endpoints
router.get('/', validate(payoutFilterSchema), getMyPayouts);
router.get('/history', getPayoutHistory);
router.get('/schedule', getPayoutSchedule);

// Admin / Group Creator action endpoints
router.post('/:id/approve', approvePayout);
router.post('/:id/reject', rejectPayout);

// Single resource endpoints
router.get('/:id', getPayoutById);
router.put('/:id', requireRole('system_admin'), validate(updatePayoutSchema), updatePayout);
router.delete('/:id', requireRole('system_admin'), deletePayout);

export default router;
