import * as groupService from "../services/group.service.js";

export async function createGroup(req, res, next) {
    try {
        const group = await groupService.createGroup(
            req.body,
            req.user.userId
        );

        res.status(201).json({
            success: true,
            message: "Group created successfully",
            data: group,
        });
    } catch (err) {
        next(err);
    }
}

export  async function getGroups  (req, res, next) {
     try {
        const groups = await groupService.getGroups();

        res.status(200).json({
            success: true,
            message: "Groups retrieved successfully",
            data: groups,
        });
    } catch (err) {
        next(err);
    }
};
export async function getGroupById(req, res, next) {
    try {
        const group = await groupService.getGroupById(
            req.params.groupId
        );

        res.status(200).json({
            success: true,
            message: "Group retrieved successfully",
            data: group,
        });
    } catch (err) {
        next(err);
    }
}
export async function updateGroup(req, res, next) {
    try {
        const group = await groupService.updateGroup(
            req.params.groupId,
            req.user.userId,
            req.body
        );

        res.status(200).json({
            message: "Group updated successfully",
            data: group,
        });
    } catch (err) {
        next(err);
    }
}
export async function deleteGroup(req, res, next) {
    try {

        await groupService.deleteGroup(
            req.params.groupId,
            req.user.userId
        );

        res.status(200).json({
            message: "Group deleted successfully"
        });

    } catch (err) {
        next(err);
    }
}
export async function joinGroup(req, res, next) {
    try {
        const member = await groupService.joinGroup(
            req.params.groupId,
            req.user.userId
        );

        res.status(201).json({
            message: "Joined group successfully",
            data: member,
        });
    } catch (err) {
        next(err);
    }
}
export async function leaveGroup(req, res, next) {
    try {

        await groupService.leaveGroup(
            req.params.groupId,
            req.user.userId
        );

        res.status(200).json({
            message: "Left group successfully"
        });

    } catch (err) {
        next(err);
    }
}
export const regenerateInviteCode = async (_req, _res, _next) => {};
export async function getGroupMembers(req, res, next) {
    try {
        const members = await groupService.getGroupMembers(
            req.params.groupId
        );

        res.status(200).json({
            success: true,
            message: "Members retrieved successfully",
            data: members,
        });
    } catch (err) {
        next(err);
    }
}
export const addMember = async (_req, _res, _next) => {};
export const removeMember = async (_req, _res, _next) => {};
export const updateMemberRole = async (_req, _res, _next) => {};
export const startGroup = async (_req, _res, _next) => {};
export const endGroup = async (_req, _res, _next) => {};
export const getGroupDashboard = async (_req, _res, _next) => {};
export const getGroupActivity = async (_req, _res, _next) => {};
