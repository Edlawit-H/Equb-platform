import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import * as userController from "../controllers/users.controller.js";
const router = Router();
router.patch("/me",protect,userController.updateMyProfile);
router.patch("/me/password",protect,userController.changePassword);
router.get("/me/dashboard",protect,userController.getDashboard);
router.get("/:id/groups",protect,userController.getUserGroups);
export default router;
