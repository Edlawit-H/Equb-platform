import pool from "../config/db.js";
import { phoneLookupVariants } from "../utils/phone.js";


export const findUserByPhone = async (phone) => {
  const variants = phoneLookupVariants(phone);

  const result = await pool.query(
    `
    SELECT *
    FROM users
    WHERE phone_number = ANY($1::text[])
    LIMIT 1
    `,
    [variants]
  );

  return result.rows[0];

};



export const createUser = async (data) => {

  const result = await pool.query(
    `
    INSERT INTO users
    (
      full_name,
      phone_number,
      password_hash
    )
    VALUES ($1,$2,$3)
    RETURNING *
    `,
    [
      data.full_name,
      data.phone_number,
      data.password_hash
    ]
  );


  return result.rows[0];

};

export const findUserByPhoneForLogin = async (phone) => {
  const variants = phoneLookupVariants(phone);

  const result = await pool.query(
    `
    SELECT *
    FROM users
    WHERE phone_number = ANY($1::text[])
    LIMIT 1
    `,
    [variants],
  );

  return result.rows[0];
};


export const updatePassword = async (
  phone_number,
  password_hash
) => {

  const result = await pool.query(
    `
    UPDATE users
    SET password_hash = $1
    WHERE phone_number = $2
    RETURNING *
    `,
    [
      password_hash,
      phone_number
    ]
  );


  return result.rows[0];

};