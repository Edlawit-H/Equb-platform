export const validate = (schema) => (req, _res, next) => {
  const result = schema.safeParse({
    body: req.body,
    query: req.query,
    params: req.params,
  });

  if (!result.success) {
    _res.status(400).json({
      status: 'error',
      message: 'Validation failed',
      details: result.error.flatten().fieldErrors,
    });
    return;
  }

  next();
};
