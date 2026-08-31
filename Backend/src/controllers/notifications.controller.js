import * as notificationService from '../services/notification.service.js';

export const getNotifications = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { is_read, type, limit, offset, page } = req.query;

    const computedOffset = page ? (Number(page) - 1) * (Number(limit) || 20) : offset;

    const result = await notificationService.getUserNotifications(userId, {
      is_read,
      type,
      limit,
      offset: computedOffset,
    });

    res.status(200).json({
      success: true,
      total: result.total,
      unread_count: result.unread_count,
      data: result.notifications,
    });
  } catch (error) {
    next(error);
  }
};

export const getNotificationById = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { id } = req.params;

    const notification = await notificationService.getNotificationById(userId, id);

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    next(error);
  }
};

export const createNotification = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const notification = await notificationService.createNotification(userId, req.body);

    res.status(201).json({
      success: true,
      message: 'Notification created successfully',
      data: notification,
    });
  } catch (error) {
    next(error);
  }
};

export const updateNotification = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { id } = req.params;

    const updated = await notificationService.updateNotification(userId, id, req.body);

    res.status(200).json({
      success: true,
      message: 'Notification updated successfully',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteNotification = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { id } = req.params;

    const result = await notificationService.deleteNotification(userId, id);

    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { id } = req.params;

    const updated = await notificationService.markAsRead(userId, id);

    res.status(200).json({
      success: true,
      message: 'Notification marked as read',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

export const markAllAsRead = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const result = await notificationService.markAllAsRead(userId);

    res.status(200).json({
      success: true,
      message: result.message,
      updated_count: result.updated_count,
    });
  } catch (error) {
    next(error);
  }
};

export const getUnread = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const { limit, offset } = req.query;

    const result = await notificationService.getUnreadNotifications(userId, {
      limit,
      offset,
    });

    res.status(200).json({
      success: true,
      unread_count: result.unread_count,
      data: result.notifications,
    });
  } catch (error) {
    next(error);
  }
};

export const sendNotification = async (req, res, next) => {
  try {
    const senderId = req.userId || req.user?.userId;
    const result = await notificationService.sendNotification(senderId, req.body);

    res.status(201).json({
      success: true,
      message: result.message,
      sent_count: result.sent_count,
      data: result.notification,
    });
  } catch (error) {
    next(error);
  }
};

export const getNotificationSettings = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const settings = await notificationService.getNotificationSettings(userId);

    res.status(200).json({
      success: true,
      data: settings,
    });
  } catch (error) {
    next(error);
  }
};

export const updateNotificationSettings = async (req, res, next) => {
  try {
    const userId = req.userId || req.user?.userId;
    const settings = await notificationService.updateNotificationSettings(userId, req.body);

    res.status(200).json({
      success: true,
      message: 'Notification settings updated successfully',
      data: settings,
    });
  } catch (error) {
    next(error);
  }
};
