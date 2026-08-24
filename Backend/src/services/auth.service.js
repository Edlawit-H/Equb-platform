import pool from "../config/db.js";
import bcrypt from "bcrypt";

import {
  findUserByPhone,
  createUser
} from "../models/users.model.js";

import {
  createOTP,
  findValidOTP
} from "../models/otp.model.js";

import {
  generateOTP
} from "../utils/otp.js";


import {
  findUserByPhoneForLogin
} from "../models/users.model.js";

import {
  findValidResetOTP
} from "../models/otp.model.js";


import {
  updatePassword
} from "../models/users.model.js";

import { sanitizeUser } from "../utils/sanitizeUser.js";
import { generateToken } from "../utils/token.js";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken
} from "../utils/jwt.js";
import { AppError } from "../utils/AppError.js";
import { isValidPhoneNumber } from "../utils/phone.js";

export const registerUser = async (data) => {
  if (!data?.phone_number || !isValidPhoneNumber(data.phone_number)) {
    throw new AppError("Please provide a valid phone number (e.g. 0912345678 or +251912345678)", 400);
  }

  const existing =
    await findUserByPhone(
      data.phone_number);


  if (existing) {
    throw new AppError("User already exists", 409);
  }


  const otp = generateOTP();

  const expiresAt =
    new Date(
      Date.now() + 5 * 60 * 1000
    );



  await createOTP({

    phone_number: data.phone_number,
    otp_code: otp,
    purpose: "registration",
    expires_at: expiresAt

  });


  // Development only
  console.log(
    "OTP:",
    otp
  );

  return {
    message: "OTP generated"
  };

};




export const verifyRegistrationOTP =
  async (data) => {
    if (!data?.phone_number || !data?.otp_code || !data?.password || !data?.full_name) {
      throw new AppError("All fields are required", 400);
    }

    if (!isValidPhoneNumber(data.phone_number)) {
      throw new AppError("Please provide a valid phone number", 400);
    }

    if (data.full_name.trim().length < 2) {
      throw new AppError("Full name must be at least 2 characters", 400);
    }

    if (data.password.length < 6) {
      throw new AppError("Password must be at least 6 characters", 400);
    }

    const client =
      await pool.connect();
    try {
      await client.query("BEGIN");

      const otpRecord =
        await findValidOTP(
          data.phone_number,
          data.otp_code
        );


      if (!otpRecord) {
        throw new AppError("Invalid or expired OTP", 400);
      }


      const hashedPassword =
        await bcrypt.hash(
          data.password,
          10
        );

      const user =
        await createUser({
          full_name: data.full_name,
          phone_number: data.phone_number,
          email: data.email || null,
          password_hash: hashedPassword,
        }, client);


      // Create default wallet
      await client.query(
        `
        INSERT INTO wallets (user_id, balance)
        VALUES ($1, 0.00);
        `,
        [user.user_id]
      );

      // Create default notification preferences
      await client.query(
        `
        INSERT INTO notification_preferences (
          user_id,
          push_notifications,
          sms_notifications,
          email_notifications
        )
        VALUES ($1, true, true, true);
        `,
        [user.user_id]
      );


      await client.query(
        `
UPDATE otp_codes
SET verified = true
WHERE otp_id=$1
`,
        [
          otpRecord.otp_id
        ]
      );

      await client.query("COMMIT");

      const safeUser = sanitizeUser(user);
      const payload = {
        userId: user.user_id,
        role: user.role,
      };
      const accessToken = generateAccessToken(payload);
      const refreshToken = generateRefreshToken(payload);

      return {
        user: safeUser,
        accessToken,
        refreshToken,
      };


    } catch (error) {

      await client.query(
        "ROLLBACK"
      );

      throw error;

    } finally {


      client.release();

    }
  };


export const loginUser = async (data) => {
  if (!data?.phone_number || !data?.password) {
    throw new AppError("Phone number and password are required", 400);
  }

  if (!isValidPhoneNumber(data.phone_number)) {
    throw new AppError("Please provide a valid phone number", 400);
  }

  const user =
    await findUserByPhoneForLogin(
      data.phone_number
    );


  if (!user) {
    throw new AppError("Invalid phone number or password", 401);
  }

  if (!user.password_hash?.startsWith('$2')) {
    throw new AppError(
      "Account password is not set up correctly. Reset the password or re-register.",
      500,
    );
  }

  const passwordMatch = await bcrypt.compare(
    data.password,
    user.password_hash,
  );

  if (!passwordMatch) {
    throw new AppError("Invalid phone number or password", 401);
  }

  const safeUser = sanitizeUser(user);
  const payload = {
    userId: user.user_id,
    role: user.role,
  };
  const token = generateToken(user);
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  return {
    user: safeUser,
    accessToken,
    refreshToken,
  };

};


export const resendRegistrationOTP = async (data) => {

  const existing = await findUserByPhone(
    data.phone_number
  );

  // User must NOT already be registered
  if (existing) {
    throw new Error("User already exists");
  }

  const otp = generateOTP();

  const expiresAt = new Date(
    Date.now() + 5 * 60 * 1000
  );

  // Invalidate previous registration OTPs
  await pool.query(
    `
    UPDATE otp_codes
    SET verified = true
    WHERE phone_number = $1
      AND purpose = 'registration'
      AND verified = false
    `,
    [data.phone_number]
  );

  // Create new OTP
  await createOTP({
    phone_number: data.phone_number,
    otp_code: otp,
    purpose: "registration",
    expires_at: expiresAt
  });

  // Development only
  console.log("New OTP:", otp);

  return {
    message: "OTP resent successfully"
  };
};




export const requestPasswordReset = async (phone_number) => {

  const user =
    await findUserByPhone(phone_number);


  if (!user) {

    throw new Error(
      "User not found"
    );

  }


  const otp = generateOTP();


  const expiresAt =
    new Date(
      Date.now() + 5 * 60 * 1000
    );


  await createOTP({

    phone_number,

    otp_code: otp,

    purpose: "forgot_password",

    expires_at: expiresAt

  });


  // Development only
  console.log(
    "Reset OTP:",
    otp
  );


  return {
    message: "OTP sent"
  };

};



export const resetPassword = async (data) => {


  const client = await pool.connect();


  try {


    await client.query("BEGIN");



    // 1. Check OTP

    const otpRecord =
      await findValidResetOTP(
        data.phone_number,
        data.otp_code
      );



    if (!otpRecord) {

      throw new Error(
        "Invalid or expired OTP"
      );

    }



    // 2. Hash new password

    const hashedPassword =
      await bcrypt.hash(
        data.new_password,
        10
      );



    // 3. Update password

    const user =
      await updatePassword(
        data.phone_number,
        hashedPassword
      );



    // 4. Mark OTP used

    await client.query(
      `
UPDATE otp_codes
SET verified = TRUE
WHERE otp_id = $1
`,
      [
        otpRecord.otp_id
      ]
    );



    await client.query(
      "COMMIT"
    );



    return {
      message: "Password updated successfully"
    };



  } catch (error) {


    await client.query(
      "ROLLBACK"
    );


    throw error;


  } finally {


    client.release();


  }


};

export const refreshAccessToken = async (refreshToken) => {
  if (!refreshToken) {
    throw new AppError("Refresh token required", 400);
  }

  try {
    const decoded = verifyRefreshToken(refreshToken);

    const payload = {
      userId: decoded.userId,
      role: decoded.role,
    };

    const accessToken = generateAccessToken(payload);
    const newRefreshToken = generateRefreshToken(payload);

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  } catch (error) {
    throw new AppError("Invalid or expired refresh token", 401);
  }
};