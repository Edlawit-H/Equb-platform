import pool from "../config/db.js";
import bcrypt from "bcrypt";

import {
  findUserByPhone,
  createUser
} from "../models/users.model.js";

import {
  createOTP,
  findValidOTP
} from "../models/otp.model.js";

import {
  generateOTP
} from "../utils/otp.js";


import {
  findUserByPhoneForLogin
} from "../models/users.model.js";

import {
  findValidResetOTP
} from "../models/otp.model.js";


import {
  updatePassword
} from "../models/users.model.js";

import { sanitizeUser } from "../utils/sanitizeUser.js";
import { generateToken } from "../utils/token.js";
import { generateAccessToken, generateRefreshToken } from "../utils/jwt.js";



export const registerUser = async(data)=>{


  const existing =
    await findUserByPhone(
      data.phone_number);


      if(existing){
    throw new Error(
      "User already exists");}


  const otp = generateOTP();

  const expiresAt =
    new Date(
      Date.now() + 5 * 60 * 1000
    );



  await createOTP({

    phone_number:data.phone_number,
    otp_code:otp,
    purpose:"registration",
    expires_at:expiresAt

  });


  // Development only
  console.log(
    "OTP:",
    otp
  );

  return {
    message:"OTP generated"
  };

};




export const verifyRegistrationOTP =
async(data)=>{


const client =
await pool.connect();
try{

await client.query("BEGIN");


const otpRecord =
await findValidOTP(
  data.phone_number,
  data.otp_code
);



if(!otpRecord){
 throw new Error(
   "Invalid or expired OTP");}


const hashedPassword =
await bcrypt.hash(data.password,10);



const userResult =
await client.query(
`
INSERT INTO users
(
 phone_number,
 password_hash,
 full_name
)
VALUES($1,$2,$3)
RETURNING *
`,
[
 data.phone_number,
 hashedPassword,
 data.full_name
]
);


const user =
userResult.rows[0];



await client.query(
`
UPDATE otp_codes
SET user_id=$1,
    verified=true
WHERE otp_id=$2
`,
[
 user.user_id,
 otpRecord.otp_id
]
);



await client.query("COMMIT");


const safeUser = sanitizeUser(user);

const token = generateToken(user);
const payload = {
  userId: user.user_id,
  role: user.role,
};
const accessToken = generateAccessToken(payload);
const refreshToken = generateRefreshToken(payload);

return {
    user: safeUser,
    accessToken,
    refreshToken,
};


}catch(error){

await client.query(
"ROLLBACK"
);

throw error;

}finally{


client.release();

}
};


export const loginUser = async (data) => {

  const user =
    await findUserByPhoneForLogin(
      data.phone_number
    );


  if (!user) {

    throw new Error(
      "Invalid phone number or password"
    );

  }


  const passwordMatch =
    await bcrypt.compare(
      data.password,
      user.password_hash
    );


  if (!passwordMatch) {

    throw new Error(
      "Invalid phone number or password"
    );

  }

const safeUser = sanitizeUser(user);
const payload = {
  userId: user.user_id,
  role: user.role,
};
const token = generateToken(user);
const accessToken = generateAccessToken(payload);
const refreshToken = generateRefreshToken(payload);

return {
    user: safeUser,
    accessToken,
    refreshToken,
};

};


export const resendRegistrationOTP = async (data) => {

  const existing = await findUserByPhone(
    data.phone_number
  );

  // User must NOT already be registered
  if (existing) {
    throw new Error("User already exists");
  }

  const otp = generateOTP();

  const expiresAt = new Date(
    Date.now() + 5 * 60 * 1000
  );

  // Invalidate previous registration OTPs
  await pool.query(
    `
    UPDATE otp_codes
    SET verified = true
    WHERE phone_number = $1
      AND purpose = 'registration'
      AND verified = false
    `,
    [data.phone_number]
  );

  // Create new OTP
  await createOTP({
    phone_number: data.phone_number,
    otp_code: otp,
    purpose: "registration",
    expires_at: expiresAt
  });

  // Development only
  console.log("New OTP:", otp);

  return {
    message: "OTP resent successfully"
  };
};




export const requestPasswordReset = async (phone_number) => {

  const user =
    await findUserByPhone(phone_number);


  if (!user) {

    throw new Error(
      "User not found"
    );

  }


  const otp = generateOTP();


  const expiresAt =
    new Date(
      Date.now() + 5 * 60 * 1000
    );


  await createOTP({

    phone_number,

    otp_code: otp,

    purpose: "forgot_password",

    expires_at: expiresAt

  });


  // Development only
  console.log(
    "Reset OTP:",
    otp
  );


  return {
    message:"OTP sent"
  };

};



export const resetPassword = async(data)=>{


const client = await pool.connect();


try{


await client.query("BEGIN");



// 1. Check OTP

const otpRecord =
await findValidResetOTP(
  data.phone_number,
  data.otp_code
);



if(!otpRecord){

throw new Error(
  "Invalid or expired OTP"
);

}



// 2. Hash new password

const hashedPassword =
await bcrypt.hash(
  data.new_password,
  10
);



// 3. Update password

const user =
await updatePassword(
  data.phone_number,
  hashedPassword
);



// 4. Mark OTP used

await client.query(
`
UPDATE otp_codes
SET verified = TRUE
WHERE otp_id = $1
`,
[
 otpRecord.otp_id
]
);



await client.query(
"COMMIT"
);



return {
 message:"Password updated successfully"
};



}catch(error){


await client.query(
"ROLLBACK"
);


throw error;


}finally{


client.release();


}


};

export const refreshAccessToken = async (refreshToken) => {

  if (!refreshToken) {
    throw new Error("Refresh token required");
  }

  try {

    const decoded = jwt.verify(
      refreshToken,
      process.env.REFRESH_TOKEN_SECRET
    );

    const payload = {
      userId: decoded.userId,
      role: decoded.role,
    };

    const accessToken =
      generateAccessToken(payload);

    return {
      accessToken,
    };

  } catch (error) {

    throw new Error(
      "Invalid or expired refresh token"
    );

  }
};