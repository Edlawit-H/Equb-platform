import * as userService from "../services/user.service.js";

export async function getMyProfile(req, res, next) {
  try {
    const user = await userService.getMyProfile(req.user.userId);
    res.status(200).json({ message: "Profile retrieved successfully", data: user });
  } catch (err) {
    next(err);
  }
}

export async function getDashboard(req, res, next) {
  try {
    const dashboard = await userService.getDashboard(req.user.userId);
    res.status(200).json({ message: "Dashboard retrieved successfully", data: dashboard });
  } catch (err) {
    next(err);
  }
}

export async function updateMyProfile(req, res, next) {
  try {
    const user = await userService.updateMyProfile(req.user.userId, req.body);
    res.status(200).json({ message: "Profile updated successfully", data: user });
  } catch (err) {
    next(err);
  }
}

export async function requestPasswordChangeOTP(req, res, next) {
  try {
    const result = await userService.requestPasswordChangeOTP(req.user.userId, req.body);
    res.status(200).json({
      message: result.message || "Verification code sent successfully",
      phone: result.phone,
      masked_phone: result.masked_phone,
      ...(result.otp !== undefined && { otp: result.otp }),
    });
  } catch (err) {
    next(err);
  }
}

export async function changePassword(req, res, next) {
  try {
    const result = await userService.changePassword(req.user.userId, req.body);
    res.status(200).json({ message: result?.message || "Password changed successfully" });
  } catch (err) {
    next(err);
  }
}

export async function getUserGroups(req, res, next) {
  try {
    const groups = await userService.getUserGroups(req.user.userId);
    res.status(200).json({ message: "User groups retrieved successfully", data: groups });
  } catch (err) {
    next(err);
  }
}
