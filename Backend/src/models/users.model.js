import pool from "../config/db.js";
import { phoneLookupVariants } from "../utils/phone.js";

export const findUserByPhone = async (phone) => {
  const variants = phoneLookupVariants(phone);
  const { rows } = await pool.query(
    `SELECT * FROM users WHERE phone_number = ANY($1::text[]) LIMIT 1`,
    [variants]
  );
  return rows[0];
};

export const findUserByPhoneForLogin = async (phone) => {
  const variants = phoneLookupVariants(phone);
  const { rows } = await pool.query(
    `SELECT * FROM users WHERE phone_number = ANY($1::text[]) LIMIT 1`,
    [variants]
  );
  return rows[0];
};

export const updatePassword = async (phone_number, password_hash) => {
  const { rows } = await pool.query(
    `UPDATE users SET password_hash=$1 WHERE phone_number=$2 RETURNING *`,
    [password_hash, phone_number]
  );
  return rows[0];
};
