import * as authService from "../services/auth.service.js";

export const register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);
    res.status(200).json({ message: "OTP sent", data: result });
  } catch (err) {
    next(err);
  }
};

export const verifyOTP = async (req, res, next) => {
  try {
    const user = await authService.verifyRegistrationOTP(req.body);
    res.status(201).json({ message: "Account created successfully", data: user });
  } catch (err) {
    next(err);
  }
};

export const login = async (req, res, next) => {
  try {
    const result = await authService.loginUser(req.body);
    res.status(200).json({ message: "Login successful", data: result });
  } catch (err) {
    next(err);
  }
};

export const refreshToken = async (req, res, next) => {
  try {
    const token = req.body.refreshToken || req.body.refresh_token;
    const result = await authService.refreshAccessToken(token);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
};

export const forgotPassword = async (req, res, next) => {
  try {
    const result = await authService.requestPasswordReset(req.body.phone_number);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

export const resetPassword = async (req, res, next) => {
  try {
    const result = await authService.resetPassword(req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

export const resendOTP = async (req, res, next) => {
  try {
    const result = await authService.resendRegistrationOTP(req.body);
    res.status(200).json({
      success: true,
      message: result.message,
      ...(result.otp !== undefined && { otp: result.otp }),
    });
  } catch (err) {
    next(err);
  }
};
