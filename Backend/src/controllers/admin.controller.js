const notImplemented = (_req, res) =>
  res.status(501).json({ status: "error", message: "Not implemented" });

export const getAdminDashboard = notImplemented;
export const getAllUsers      = notImplemented;
export const getAllGroups     = notImplemented;
export const deleteUser       = notImplemented;
export const updateUserStatus = notImplemented;
export const getAuditLogs     = notImplemented;
export const getSystemHealth  = notImplemented;
