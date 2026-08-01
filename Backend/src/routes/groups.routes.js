import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import { getGroupContributions } from '../controllers/contributions.controller.js';

const router = Router();

router.use(protect);

// GET /api/v1/groups/:id/contributions — all contributions for a group (Edlawit-owned)
router.get('/:id/contributions', getGroupContributions);

export default router;
