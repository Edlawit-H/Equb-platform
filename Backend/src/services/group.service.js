import pool from "../config/db.js";
import crypto from "crypto";

function generateInvitationCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
}

export async function createGroup(data, userId) {
    const client = await pool.connect();
    const {
    group_name,
    description,
    contribution_amount,
    cycle_duration,
    max_members,
    selection_mode = 'positional',
    contribution_deadline_days = 1,
} = data;
    try {
        await client.query("BEGIN");

        const invitation_code = generateInvitationCode();

        const { rows } = await client.query(
            `
            INSERT INTO equb_groups (
                group_name,
                description,
                admin_id,
                invitation_code,
                contribution_amount,
                cycle_duration,
                max_members,
                selection_mode,
                contribution_deadline_days
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
            RETURNING *;
            `,
            [
                group_name,
                description,
                userId,
                invitation_code,
                contribution_amount,
                cycle_duration,
                max_members,
                selection_mode,
                contribution_deadline_days,
            ]
        );

        if (rows.length !== 1) {
            throw new Error("Failed to create group");
        }

        const group = rows[0];
        
        await client.query(
            `
            INSERT INTO group_members (
                group_id,
                user_id,
                role,
                position_in_cycle
            )
            VALUES ($1,$2,$3,$4);
            `,
            [
                group.group_id,
                userId,
                "admin",
                1,
            ]
        );

        await client.query("COMMIT");

        return group;

    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
}

export async function getGroups() {
    const { rows } = await pool.query(
        `
        SELECT *
        FROM equb_groups
        WHERE is_deleted = FALSE
        ORDER BY created_at DESC;
        `
    );

    return rows;
}

export async function getGroupById(groupId) {
    const { rows } = await pool.query(
        `
        SELECT *
        FROM equb_groups
        WHERE group_id = $1
          AND is_deleted = FALSE;
        `,
        [groupId]
    );

    if (rows.length !== 1) {
        throw new Error("Group not found");
    }

    return rows[0];
}



export async function joinGroup(groupId, userId) {

    // Check if group exists
    const { rows } = await pool.query(
        `
        SELECT
            group_id,
            max_members,
            status
        FROM equb_groups
        WHERE group_id = $1
        AND is_deleted = FALSE;
        `,
        [groupId]
    );

    if (rows.length !== 1) {
        throw new Error("Group not found");
    }

    const group = rows[0];

    if (group.status === 'active' || group.status === 'completed') {
        throw new Error("Cannot join a group that has already started");
    }

    if (await isMember(userId, groupId)) {
        throw new Error("User is already a member");
    }
    // Check if group is full
    const { rows: countRows } = await pool.query(
        `
        SELECT COUNT(*) AS member_count
        FROM group_members
        WHERE group_id = $1;
        `,
        [groupId]
    );

    const memberCount = Number(countRows[0].member_count);

    if (memberCount >= group.max_members) {
        throw new Error("Group is full");
    }

    const nextPosition = memberCount + 1;

    const { rows: joinedRows } = await pool.query(
        `
        INSERT INTO group_members (
            group_id,
            user_id,
            role,
            position_in_cycle
        )
        VALUES ($1, $2, $3, $4)
        RETURNING *;
        `,
        [
            groupId,
            userId,
            "member",
            nextPosition,
        ]
    );

    return joinedRows[0];
}

export async function getGroupMembers(groupId) {
    const { rows } = await pool.query(
        `
        SELECT
            gm.member_id,
            gm.role,
            u.user_id,
            u.full_name,
            u.phone_number,
            u.profile_image
        FROM group_members gm
        INNER JOIN users u
            ON gm.user_id = u.user_id
        WHERE gm.group_id = $1
        ORDER BY gm.join_date ASC;
        `,
        [groupId]
    );

    return rows;
}


export async function updateGroup(groupId, userId, data) {

    // Check group exists
    const { rows } = await pool.query(
        `
        SELECT
            group_id,
            admin_id
        FROM equb_groups
        WHERE group_id = $1
        AND is_deleted = FALSE;
        `,
        [groupId]
    );

    if (rows.length !== 1) {
        throw new Error("Group not found");
    }

    const group = rows[0];

    // Authorization
 if (!(await isGroupAdmin(userId, groupId))) {
    throw new Error("Only the group admin can update this group");
}

    // Allowed fields
    const allowedFields = [
        "group_name",
        "description",
        "contribution_amount",
        "cycle_duration",
        "max_members",
        "start_date",
        "end_date",
        "status"
    ];

    const updates = [];
    const values = [];

    // Build dynamic update
    for (const field of allowedFields) {

        if (data[field] !== undefined) {

            values.push(data[field]);

            updates.push(
                `${field} = $${values.length}`
            );

        }

    }

    if (updates.length === 0) {
        throw new Error("No valid fields provided for update");
    }

    values.push(groupId);

    const query = `
        UPDATE equb_groups
        SET ${updates.join(", ")}
        WHERE group_id = $${values.length}
        RETURNING *;
    `;

    const { rows: updatedRows } = await pool.query(
        query,
        values
    );

    return updatedRows[0];
}


export async function getMembership(userId, groupId) {

    const { rows } = await pool.query(
        `
        SELECT *
        FROM group_members
        WHERE user_id = $1
        AND group_id = $2;
        `,
        [userId, groupId]
    );

    return rows[0] || null;
}

export async function isMember(userId, groupId) {

    const membership = await getMembership(
        userId,
        groupId
    );

    return !!membership;
}

export async function isGroupAdmin(userId, groupId) {

    const { rows } = await pool.query(
        `
        SELECT admin_id
        FROM equb_groups
        WHERE group_id = $1
        AND is_deleted = FALSE;
        `,
        [groupId]
    );

    if (rows.length !== 1) {
        return false;
    }

    return rows[0].admin_id === userId;
}




export async function leaveGroup(groupId, userId) {

    // Check membership
    const membership = await getMembership(
        userId,
        groupId
    );

    if (!membership) {
        throw new Error(
            "You are not a member of this group"
        );
    }

    // Prevent admin from leaving
    if (await isGroupAdmin(userId, groupId)) {
        throw new Error(
            "Group admin cannot leave the group"
        );
    }

    // Remove membership
    await pool.query(
        `
        DELETE FROM group_members
        WHERE member_id = $1;
        `,
        [membership.member_id]
    );
}


export async function deleteGroup(groupId, userId) {

    // Check group exists
    const { rows } = await pool.query(
        `
        SELECT group_id
        FROM equb_groups
        WHERE group_id = $1
        AND is_deleted = FALSE;
        `,
        [groupId]
    );

    if (rows.length !== 1) {
        throw new Error("Group not found");
    }

    // Only admin can delete
    if (!(await isGroupAdmin(userId, groupId))) {
        throw new Error(
            "Only the group admin can delete this group"
        );
    }

    // Soft delete
    await pool.query(
        `
        UPDATE equb_groups
        SET is_deleted = TRUE
        WHERE group_id = $1;
        `,
        [groupId]
    );

}

export async function startGroup(groupId, userId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      `SELECT * FROM equb_groups WHERE group_id = $1 AND is_deleted = FALSE`,
      [groupId]
    );
    if (rows.length === 0) throw new Error('Group not found');

    const group = rows[0];

    if (!(await isGroupAdmin(userId, groupId))) {
      throw new Error('Only the group admin can start this group');
    }

    if (group.status === 'active') throw new Error('Group has already started');
    if (group.status === 'completed') throw new Error('Group is already completed');

    const { rows: members } = await client.query(
      `SELECT member_id FROM group_members WHERE group_id = $1 AND status = 'active'`,
      [groupId]
    );

    const actualMemberCount = members.length;

    if (actualMemberCount < 2) {
      throw new Error('At least 2 members are required to start a group');
    }

    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + actualMemberCount * group.cycle_duration);

    const dueDate = new Date(startDate);
    dueDate.setDate(dueDate.getDate() + (group.contribution_deadline_days ?? 1));

    const cycleEndDate = new Date(startDate);
    cycleEndDate.setDate(cycleEndDate.getDate() + group.cycle_duration);

    await client.query(
      `UPDATE equb_groups
       SET status = 'active', start_date = $1, end_date = $2, cycle_end_date = $3, total_cycles = $4
       WHERE group_id = $5`,
      [
        startDate.toISOString().split('T')[0],
        endDate.toISOString().split('T')[0],
        cycleEndDate.toISOString().split('T')[0],
        actualMemberCount,
        groupId,
      ]
    );

    for (const member of members) {
      await client.query(
        `INSERT INTO contributions (member_id, group_id, cycle_number, amount, due_date, status)
         VALUES ($1, $2, 1, $3, $4, 'pending')`,
        [member.member_id, groupId, group.contribution_amount, dueDate.toISOString().split('T')[0]]
      );
    }

    await client.query('COMMIT');

    return {
      group_id: groupId,
      status: 'active',
      start_date: startDate.toISOString().split('T')[0],
      end_date: endDate.toISOString().split('T')[0],
      cycle_1_due_date: dueDate.toISOString().split('T')[0],
      total_cycles: actualMemberCount,
      members_count: actualMemberCount,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
