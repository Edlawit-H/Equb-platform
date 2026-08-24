/**
 * @typedef {Object} EqubGroup
 * @property {string} group_id
 * @property {string} group_name
 * @property {string|null} description
 * @property {string} admin_id
 * @property {string} invitation_code
 * @property {number} contribution_amount
 * @property {1|7|14|30} cycle_duration
 * @property {number} max_members
 * @property {number} current_cycle
 * @property {Date|null} start_date
 * @property {Date|null} end_date
 * @property {'pending'|'ready'|'active'|'completed'|'cancelled'} status
 * @property {boolean} is_deleted
 * @property {Date} created_at
 */

/**
 * @typedef {Object} GroupMember
 * @property {string} member_id
 * @property {string} user_id
 * @property {string} group_id
 * @property {Date} join_date
 * @property {number} position_in_cycle
 * @property {'admin'|'co_admin'|'member'} role
 * @property {'active'|'removed'|'left'} status
 */
