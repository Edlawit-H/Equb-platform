import pool from "../config/db.js";

export async function createGroup(data, userId) {
    const client = await pool.connect();
    const {
    group_name,
    description,
    contribution_amount,
    cycle_duration,
    max_members,
    start_date,
    end_date,
} = data;
    try {
        await client.query("BEGIN");

        // Step 1: Create the group
        const { rows } = await client.query(
            `
            INSERT INTO equb_groups (
                group_name,
                description,
                admin_id,
                contribution_amount,
                cycle_duration,
                max_members,
                start_date,
                end_date
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *;
            `,
            [
                group_name,
                description,
                userId,
                contribution_amount,
                cycle_duration,
                max_members,
                start_date,
                end_date,
            ]
        );

        if (rows.length !== 1) {
            throw new Error("Failed to create group");
        }

        const group = rows[0];
        
        // Step 2: Add creator as first member
        await client.query(
            `
            INSERT INTO group_members (
                group_id,
                user_id,
                role
            )
            VALUES ($1,$2,$3);
            `,
            [
                group.group_id,
                userId,
                "admin",
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

    // Check if already a member
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

    // Add member
    const { rows: joinedRows } = await pool.query(
        `
        INSERT INTO group_members (
            group_id,
            user_id,
            role
        )
        VALUES ($1, $2, $3)
        RETURNING *;
        `,
        [
            groupId,
            userId,
            "member",
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
        ORDER BY gm.joined_at ASC;
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