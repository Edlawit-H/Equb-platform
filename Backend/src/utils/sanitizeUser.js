export const sanitizeUser = (user) => {

  const {
    password_hash,
    ...safeUser
  } = user;


  return safeUser;

};