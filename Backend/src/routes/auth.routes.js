import { Router } from 'express';
import {
 register,
 verifyOTP,
 login,
 forgotPassword,
 resetPassword,
 profile
} from "../controllers/auth.controller.js";

import { protect } from "../middleware/auth.middleware.js";

const router = Router();

router.get("/profile",protect,profile);

router.post("/register", register);

router.post("/verify-otp", verifyOTP);

router.post("/login", login);

router.post("/forgot-password",forgotPassword);

router.post("/reset-password",resetPassword);
export default router;
