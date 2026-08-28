import request from 'supertest';
import app from '../app.js';
import { generateRefreshToken } from '../utils/jwt.js';

describe('Auth', () => {
  it('POST /api/v1/auth/register - returns 400 when body is missing', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({});
    expect(res.status).toBe(400);
  });

  it('POST /api/v1/auth/login - returns 400 when body is missing', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({});
    expect(res.status).toBe(400);
  });

  it('POST /api/v1/auth/refresh-token - returns 400 when refreshToken is missing', async () => {
    const res = await request(app).post('/api/v1/auth/refresh-token').send({});
    expect(res.status).toBe(400);
  });

  it('POST /api/v1/auth/refresh-token - returns 401 for invalid token', async () => {
    const res = await request(app).post('/api/v1/auth/refresh-token').send({
      refreshToken: 'invalid.token.here',
    });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/auth/refresh-token - returns 200 with new accessToken for valid token', async () => {
    const validRefreshToken = generateRefreshToken({ userId: 'test-user-id', role: 'member' });
    const res = await request(app).post('/api/v1/auth/refresh-token').send({
      refreshToken: validRefreshToken,
    });
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');
  });
});

