import pool from "../config/db.js";


export const findUserByPhone = async (phone) => {

  const result = await pool.query(
    `
    SELECT *
    FROM users
    WHERE phone_number = $1
    `,
    [phone]
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

  const result = await pool.query(
    `
    SELECT *
    FROM users
    WHERE phone_number = $1
    `,
    [phone]
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