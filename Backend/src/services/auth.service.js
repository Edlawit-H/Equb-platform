import pool from "../config/db.js";
import bcrypt from "bcrypt";
import { findUserByPhone, findUserByPhoneForLogin, updatePassword } from "../models/users.model.js";
import { createOTP, findValidOTP, findValidResetOTP } from "../models/otp.model.js";
import { generateOTP } from "../utils/otp.js";
import { sanitizeUser } from "../utils/sanitizeUser.js";
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from "../utils/jwt.js";
import { AppError } from "../utils/AppError.js";
import { normalizePhone } from "../utils/phone.js";

export const registerUser = async (data) => {
  if (!data?.phone_number) throw new AppError("Phone number is required", 400);

  data.phone_number = normalizePhone(data.phone_number);

  const existing = await findUserByPhone(data.phone_number);
  if (existing) throw new AppError("User already exists", 409);

  const otp = generateOTP();
  await createOTP({
    phone_number: data.phone_number,
    otp_code: otp,
    purpose: "registration",
    expires_at: new Date(Date.now() + 5 * 60 * 1000),
  });

  if (process.env.NODE_ENV !== "production") console.log("OTP:", otp);

  return { message: "OTP generated", otp };
};

export const verifyRegistrationOTP = async (data) => {
  if (!data?.phone_number || !data?.otp_code || !data?.password || !data?.full_name) {
    throw new AppError("All fields are required", 400);
  }

  data.phone_number = normalizePhone(data.phone_number);

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const otpRecord = await findValidOTP(data.phone_number, data.otp_code);
    if (!otpRecord) throw new AppError("Invalid or expired OTP", 400);

    const hashedPassword = await bcrypt.hash(data.password, 10);
    const { rows } = await client.query(
      `INSERT INTO users (phone_number, password_hash, full_name) VALUES ($1,$2,$3) RETURNING *`,
      [data.phone_number, hashedPassword, data.full_name]
    );
    const user = rows[0];

    await client.query(
      `UPDATE otp_codes SET user_id=$1, verified=true WHERE otp_id=$2`,
      [user.user_id, otpRecord.otp_id]
    );
    await client.query("COMMIT");

    const payload = { userId: user.user_id, role: user.role };
    return {
      user: sanitizeUser(user),
      accessToken: generateAccessToken(payload),
      refreshToken: generateRefreshToken(payload),
    };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

export const loginUser = async (data) => {
  if (!data?.phone_number || !data?.password) {
    throw new AppError("Phone number and password are required", 400);
  }

  data.phone_number = normalizePhone(data.phone_number);

  const user = await findUserByPhoneForLogin(data.phone_number);
  if (!user) throw new AppError("Invalid phone number or password", 401);

  if (!user.password_hash?.startsWith("$2")) {
    throw new AppError("Account password is not set up correctly. Reset the password or re-register.", 500);
  }

  const match = await bcrypt.compare(data.password, user.password_hash);
  if (!match) throw new AppError("Invalid phone number or password", 401);

  const payload = { userId: user.user_id, role: user.role };
  return {
    user: sanitizeUser(user),
    accessToken: generateAccessToken(payload),
    refreshToken: generateRefreshToken(payload),
  };
};

export const resendRegistrationOTP = async (data) => {
  const existing = await findUserByPhone(data.phone_number);
  if (existing) throw new AppError("User already exists", 409);

  const otp = generateOTP();
  await pool.query(
    `UPDATE otp_codes SET verified=true WHERE phone_number=$1 AND purpose='registration' AND verified=false`,
    [data.phone_number]
  );
  await createOTP({
    phone_number: data.phone_number,
    otp_code: otp,
    purpose: "registration",
    expires_at: new Date(Date.now() + 5 * 60 * 1000),
  });

  if (process.env.NODE_ENV !== "production") console.log("New OTP:", otp);

  return { message: "OTP resent successfully", otp };
};

export const requestPasswordReset = async (phone_number) => {
  const user = await findUserByPhone(phone_number);
  if (!user) throw new AppError("User not found", 404);

  const otp = generateOTP();
  await createOTP({
    phone_number,
    otp_code: otp,
    purpose: "forgot_password",
    expires_at: new Date(Date.now() + 5 * 60 * 1000),
  });

  if (process.env.NODE_ENV !== "production") console.log("Reset OTP:", otp);

  return { message: "OTP sent", otp };
};

export const resetPassword = async (data) => {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const otpRecord = await findValidResetOTP(data.phone_number, data.otp_code);
    if (!otpRecord) throw new AppError("Invalid or expired OTP", 400);

    const hashedPassword = await bcrypt.hash(data.new_password, 10);
    await updatePassword(data.phone_number, hashedPassword);
    await client.query(`UPDATE otp_codes SET verified=true WHERE otp_id=$1`, [otpRecord.otp_id]);

    await client.query("COMMIT");
    return { message: "Password updated successfully" };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
};

export const refreshAccessToken = async (refreshToken) => {
  if (!refreshToken) throw new AppError("Refresh token required", 400);
  try {
    const decoded = verifyRefreshToken(refreshToken);
    const payload = { userId: decoded.userId, role: decoded.role };
    return {
      accessToken: generateAccessToken(payload),
      refreshToken: generateRefreshToken(payload),
    };
  } catch {
    throw new AppError("Invalid or expired refresh token", 401);
  }
};
