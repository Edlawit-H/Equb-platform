import jwt from "jsonwebtoken";
import dotenv from "dotenv";

export const generateToken = (user) => {

  return jwt.sign(
    {
      user_id: user.user_id,
      phone_number: user.phone_number,
      role: user.role
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN
    }
  );

};