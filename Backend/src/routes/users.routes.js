import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import * as userController from "../controllers/users.controller.js";
const router = Router();
router.get("/me",protect,userController.getMyProfile);
router.patch("/me",protect,userController.updateMyProfile);
router.patch("/me/password",protect,userController.changePassword);
router.get("/me/dashboard",protect,userController.getDashboard);
export default router;
