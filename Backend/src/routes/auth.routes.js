import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
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

const authRateLimit = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 30,
	standardHeaders: true,
	legacyHeaders: false,
});


router.post("/register", authRateLimit, register);

router.post("/verify-otp", verifyOTP);

router.post("/resend-otp", authRateLimit, resendOTP);

router.post("/login", authRateLimit, login);

router.post("/forgot-password", authRateLimit, forgotPassword);

router.post("/reset-password", authRateLimit, resetPassword);

router.post("/refresh-token", refreshToken);

router.get("/profile",protect,userController.getMyProfile);
router.put("/profile",protect,userController.updateMyProfile);

export default router;