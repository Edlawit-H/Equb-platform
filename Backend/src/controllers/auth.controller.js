import * as authService from "../services/auth.service.js";

export const register = async (req, res, next) => {
     try{
  const result = await authService.registerUser(
    req.body
  );

  res.status(200).json({
    message:"OTP sent",
    data:result
  });

 }catch(err){
  next(err);
 }
};
export const verifyOTP = async (req, res, next) => {
     try{
  const user =
    await authService.verifyRegistrationOTP(
      req.body
    );

  res.status(201).json({
    message:"Account created successfully",
    data:user
  });


 }catch(err){
  next(err);
 }
};
export const login = async (req, res, next) => {
    try{
const result =
await authService.loginUser(
req.body
);

res.status(200).json({
message:"Login successful",
data:result
});

}catch(err){
next(err);
}
};
export const logout = async (_req, _res, _next) => {};
export const refreshToken = async (_req, _res, _next) => {};
export const forgotPassword = async (req, res, next) => {
try{

const result =
await authService.requestPasswordReset(
    req.body.phone_number
);

res.json(result);
}catch(err){
next(err);
}    
};
export const resetPassword = async (req, res, next) => {
try{
const result =
await authService.resetPassword(
  req.body
);
res.json(result);

}catch(err){
next(err);
}    
};
export const resendOtp = async (_req, _res, _next) => {};
export const checkPhone = async (_req, _res, _next) => {};
export const enableBiometric = async (_req, _res, _next) => {};
export const registerDevice = async (_req, _res, _next) => {};
export const unregisterDevice = async (_req, _res, _next) => {};
export const getSessions = async (_req, _res, _next) => {};
export const revokeSession = async (_req, _res, _next) => {};
export const revokeAllSessions = async (_req, _res, _next) => {};
export async function profile(req, res) {
  res.status(200).json({
    message: "Authenticated",
    user: req.user,
  });
}