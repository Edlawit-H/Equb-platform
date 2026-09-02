import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import { getGroupContributions } from '../controllers/contributions.controller.js';
import * as groupController from '../controllers/groups.controller.js';
import { getGroupPayouts, getGroupPayoutSchedule } from '../controllers/payouts.controller.js';
import * as userController from '../controllers/users.controller.js';

const router = Router();
router.use(protect);

router.post('/', groupController.createGroup);
router.post('/join', groupController.joinGroupByCode);
router.get('/', userController.getUserGroups);
router.get('/:groupId', groupController.getGroupById);
router.post('/:groupId/join', groupController.joinGroup);
router.post('/:groupId/leave', groupController.leaveGroup);
router.get('/:groupId/members', groupController.getGroupMembers);
router.patch('/:groupId', groupController.updateGroup);
router.delete('/:groupId', groupController.deleteGroup);
router.post('/:groupId/start', groupController.startGroup);
router.get('/:id/contributions', getGroupContributions);
router.get('/:id/payouts', getGroupPayouts);
router.get('/:groupId/schedule', getGroupPayoutSchedule);

export default router;