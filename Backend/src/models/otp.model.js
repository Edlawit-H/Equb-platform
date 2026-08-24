import pool from "../config/db.js";

export const createOTP = async (data) => {

  const result = await pool.query(
    `
    INSERT INTO otp_codes
    (
      phone_number,
      otp_code,
      purpose,
      expires_at
    )
    VALUES ($1,$2,$3,$4)
    RETURNING *
    `,
    [
      data.phone_number,
      data.otp_code,
      data.purpose,
      data.expires_at
    ]
  );

  return result.rows[0];
};




export const findValidOTP = async (phone_number, otp_code) => {

  const result = await pool.query(
    `
    SELECT *
    FROM otp_codes
    WHERE phone_number = $1
    AND otp_code = $2
    AND purpose = 'registration'
    AND verified = FALSE
    AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [
      phone_number,
      otp_code
    ]
  );

  return result.rows[0];

};



export const markOTPVerified = async (otp_id) => {

  const result = await pool.query(
    `
    UPDATE otp_codes
    SET verified = TRUE
    WHERE otp_id = $1
    RETURNING *
    `,
    [otp_id]
  );

  return result.rows[0];

};


export const findValidResetOTP = async (
  phone_number,
  otp_code
) => {

  const result = await pool.query(
    `
    SELECT *
    FROM otp_codes
    WHERE phone_number = $1
    AND otp_code = $2
    AND purpose = 'forgot_password'
    AND verified = FALSE
    AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [
      phone_number,
      otp_code
    ]
  );


  return result.rows[0];

};

export const findValidPhoneUpdateOTP = async (
  phone_number,
  otp_code
) => {

  const result = await pool.query(
    `
    SELECT *
    FROM otp_codes
    WHERE phone_number = $1
    AND otp_code = $2
    AND purpose = 'phone_update'
    AND verified = FALSE
    AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [
      phone_number,
      otp_code
    ]
  );

  return result.rows[0];
};