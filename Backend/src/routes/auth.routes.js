import { Router } from 'express';
import {
 register,
 verifyOTP,
 login,
 forgotPassword,
 resetPassword
} from "../controllers/auth.controller.js";

import { protect } from "../middleware/auth.middleware.js";

const router = Router();

router.get(
    "/me",
    protect,
    (req,res)=>{

        res.json({
            message:"Authenticated",
            user:req.user
        });

    }
);

router.post("/register", register);

router.post("/verify-otp", verifyOTP);

router.post("/login", login);

router.post("/forgot-password",forgotPassword);

router.post("/reset-password",resetPassword);
export default router;
