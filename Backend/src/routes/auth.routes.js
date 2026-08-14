import { Router } from 'express';
import {
 register,
 verifyOTP,
 login,
 forgotPassword,
 resetPassword,
 resendOTP,
 refreshToken
} from "../controllers/auth.controller.js";
import * as userController from "../controllers/users.controller.js";

import { protect } from "../middleware/auth.middleware.js";

const router = Router();


router.post("/register", register);

router.post("/verify-otp", verifyOTP);

router.post("/resend-otp", resendOTP);

router.post("/login", login);

router.post("/forgot-password",forgotPassword);

router.post("/reset-password",resetPassword);

router.post("/refresh-token", refreshToken);

router.get("/profile",protect,userController.getMyProfile);
router.put("/profile",protect,userController.updateMyProfile);

export default router;