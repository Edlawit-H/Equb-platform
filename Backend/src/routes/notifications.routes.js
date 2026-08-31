import { Router } from 'express';
import { protect } from '../middleware/auth.middleware.js';
import * as notificationsController from '../controllers/notifications.controller.js';

const router = Router();

// Require authentication for all notification routes
router.use(protect);

// Specific named sub-routes (must come before /:id parameter)
router.get('/unread', notificationsController.getUnread);
router.patch('/read-all', notificationsController.markAllAsRead);
router.post('/send', notificationsController.sendNotification);
router.get('/settings', notificationsController.getNotificationSettings);
router.patch('/settings', notificationsController.updateNotificationSettings);
router.put('/settings', notificationsController.updateNotificationSettings);

// Collection routes
router.get('/', notificationsController.getNotifications);
router.post('/', notificationsController.createNotification);

// Specific resource by ID routes
router.get('/:id', notificationsController.getNotificationById);
router.put('/:id', notificationsController.updateNotification);
router.delete('/:id', notificationsController.deleteNotification);
router.patch('/:id/read', notificationsController.markAsRead);

export default router;
