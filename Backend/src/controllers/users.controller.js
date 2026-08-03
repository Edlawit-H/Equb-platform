import * as userService from "../services/user.service.js";

export async function getMyProfile(req, res, next) {
    try {
        const user = await userService.getMyProfile(
            req.user.userId
        );

        res.status(200).json({
            message: "Profile retrieved successfully",
            data: user,
        });
    } catch (err) {
        next(err);
    }
}
export async function getDashboard(req, res, next) {
    try {
        const dashboard = await userService.getDashboard(
            req.user.userId
        );

        res.status(200).json({
            message: "Dashboard retrieved successfully",
            data: dashboard,
        });
    } catch (err) {
        next(err);
    }
}

export async function updateMyProfile(req, res, next) {
    try {
        const user = await userService.updateMyProfile(
            req.user.userId,
            req.body
        );

        res.status(200).json({
            message: "Profile updated successfully",
            data: user,
        });
    } catch (err) {
        next(err);
    }
}
export const uploadAvatar = async (_req, _res, _next) => {};
export async function changePassword(req, res, next) {
    try {
        await userService.changePassword(
            req.user.userId,
            req.body
        );

        res.status(200).json({
            message: "Password changed successfully",
        });
    } catch (err) {
        next(err);
    }
}
export const deleteAccount = async (_req, _res, _next) => {};
export const getUserById = async (_req, _res, _next) => {};
export const searchUsers = async (_req, _res, _next) => {};
export const getUserGroups = async (_req, _res, _next) => {};
