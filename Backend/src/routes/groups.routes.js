import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import { getGroupContributions } from '../controllers/contributions.controller.js';
import * as groupController from "../controllers/groups.controller.js";
import { getGroupPayouts } from '../controllers/payouts.controller.js';
import * as userController from "../controllers/users.controller.js";

const router = Router();

router.use(protect);
router.post("/",protect,groupController.createGroup);
router.get("/",protect,userController.getUserGroups);
router.get("/:groupId",protect,groupController.getGroupById);
router.post("/:groupId/join",protect,groupController.joinGroup);
router.post("/:groupId/leave",protect,groupController.leaveGroup);
router.get("/:groupId/members",protect,groupController.getGroupMembers);
router.patch("/:groupId",protect,groupController.updateGroup);
router.delete("/:groupId",protect,groupController.deleteGroup);
// GET /api/v1/groups/:id/contributions — all contributions for a group (Edlawit-owned)
router.get('/:id/contributions', getGroupContributions);

// GET /api/v1/groups/:id/payouts — all payouts for a group (Edlawit-owned)
router.get('/:id/payouts', getGroupPayouts);

export default router;
