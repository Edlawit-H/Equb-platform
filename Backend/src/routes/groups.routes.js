import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import { getGroupContributions } from '../controllers/contributions.controller.js';
import * as groupController from "../controllers/groups.controller.js";
const router = Router();

router.use(protect);
router.post("/",protect,groupController.createGroup);
router.get("/",protect,groupController.getMyGroups);
router.get("/:groupId",protect,groupController.getGroupById);
router.post("/:groupId/join",protect,groupController.joinGroup);
router.get("/:groupId/members",protect,groupController.getGroupMembers);
router.patch("/:groupId",protect,groupController.updateGroup);
// GET /api/v1/groups/:id/contributions — all contributions for a group (Edlawit-owned)
router.get('/:id/contributions', getGroupContributions);

export default router;
