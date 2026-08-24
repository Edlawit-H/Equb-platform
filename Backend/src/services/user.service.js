import pool from "../config/db.js";
import bcrypt from "bcrypt";

export async function getMyProfile(userId) {

    const { rows } = await pool.query(
        `
        SELECT
            user_id,
            full_name,
            phone_number,
            email,
            profile_image,
            role,
            status,
            wallet_balance,
            created_at
        FROM users
        WHERE user_id = $1
        AND is_deleted = FALSE;
        `,
        [userId]
    );

    if (rows.length !== 1) {
        throw new Error("User not found");
    }

    return rows[0];
}


export async function updateMyProfile(userId, data) {

    // Check if user exists
    const { rows: userRows } = await pool.query(
        `
        SELECT user_id
        FROM users
        WHERE user_id = $1
        AND is_deleted = FALSE;
        `,
        [userId]
    );

    if (userRows.length !== 1) {
        throw new Error("User not found");
    }

    // Check email uniqueness (only if email is provided)
    if (data.email !== undefined) {
        data.email = data.email.trim();

    if (data.email === "") {
        throw new Error("Email cannot be empty");
    }

        const { rows: emailRows } = await pool.query(
            `
            SELECT user_id
            FROM users
            WHERE email = $1
            AND user_id <> $2;
            `,
            [data.email, userId]
        );

        if (emailRows.length > 0) {
            throw new Error("Email already in use");
        }
    }

    // Fields users are allowed to update
    const allowedFields = [
        "full_name",
        "email",
        "profile_image"
    ];

    const updates = [];
    const values = [];

    // Build dynamic UPDATE query
    for (const field of allowedFields) {

        if (data[field] !== undefined && data[field] !== "") {

            values.push(data[field]);

            updates.push(
                `${field} = $${values.length}`
            );
        }
    }

    // Nothing to update
    if (updates.length === 0) {
        throw new Error("No valid fields provided for update");
    }

    // Add userId for WHERE clause
    values.push(userId);

    const query = `
        UPDATE users
        SET ${updates.join(", ")}
        WHERE user_id = $${values.length}
        RETURNING
            user_id,
            full_name,
            phone_number,
            email,
            profile_image,
            role,
            status,
            created_at
    `;

    const { rows } = await pool.query(query, values);

    return rows[0];
}


export async function changePassword(userId, data) {

    const {
        current_password,
        new_password,
    } = data;

    // Get current password hash
    const { rows } = await pool.query(
        `
        SELECT password_hash
        FROM users
        WHERE user_id = $1
        AND is_deleted = FALSE;
        `,
        [userId]
    );

    if (rows.length !== 1) {
        throw new Error("User not found");
    }

    // Verify current password
    const isMatch = await bcrypt.compare(
        current_password,
        rows[0].password_hash
    );

    if (!isMatch) {
        throw new Error("Current password is incorrect");
    }

    // Prevent using the same password
    if (current_password === new_password) {
        throw new Error(
            "New password must be different from the current password"
        );
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(
        new_password,
        10
    );

    // Update password
    await pool.query(
        `
        UPDATE users
        SET password_hash = $1
        WHERE user_id = $2;
        `,
        [
            passwordHash,
            userId,
        ]
    );
}

export async function getDashboard(userId) {

    // Profile
    const { rows: profileRows } = await pool.query(
        `
        SELECT
            user_id,
            full_name,
            phone_number,
            email,
            profile_image
        FROM users
        WHERE user_id = $1
        AND is_deleted = FALSE;
        `,
        [userId]
    );

    if (profileRows.length !== 1) {
        throw new Error("User not found");
    }

    // Groups the user belongs to
    const { rows: groupsRows } = await pool.query(
        `
        SELECT
            g.group_id,
            g.group_name,
            g.contribution_amount,
            g.cycle_duration,
            gm.role
        FROM group_members gm
        INNER JOIN equb_groups g
            ON gm.group_id = g.group_id
        WHERE gm.user_id = $1
        AND g.is_deleted = FALSE
        ORDER BY g.created_at DESC;
        `,
        [userId]
    );

    // Statistics
    const { rows: statsRows } = await pool.query(
        `
        SELECT
            COUNT(*) FILTER (WHERE role = 'admin') AS groups_created,
            COUNT(*) AS groups_joined
        FROM group_members
        WHERE user_id = $1;
        `,
        [userId]
    );

    return {
        profile: profileRows[0],
        my_groups: groupsRows,
        statistics: {
            groups_created: Number(statsRows[0].groups_created),
            groups_joined: Number(statsRows[0].groups_joined),
        },
    };
}


export async function getUserGroups(userId) {

    const { rows: userRows } = await pool.query(
        `
        SELECT user_id
        FROM users
        WHERE user_id = $1
        AND is_deleted = FALSE;
        `,
        [userId]
    );

    if (userRows.length !== 1) {
        throw new Error("User not found");
    }

    const { rows } = await pool.query(
        `
        SELECT
            g.group_id,
            g.group_name,
            g.description,
            g.invitation_code,
            g.contribution_amount,
            g.cycle_duration,
            g.max_members,
            g.start_date,
            g.end_date,
            g.status,
            gm.role,
            (
                SELECT COUNT(*)::int
                FROM group_members gm2
                WHERE gm2.group_id = g.group_id
            ) AS member_count,
            (
                SELECT COUNT(*)::int
                FROM group_members gm2
                WHERE gm2.group_id = g.group_id
            ) AS current_members
        FROM group_members gm
        INNER JOIN equb_groups g
            ON gm.group_id = g.group_id
        WHERE gm.user_id = $1
        AND g.is_deleted = FALSE
        ORDER BY g.created_at DESC
        `,
        [userId]
    );

    return rows;
}