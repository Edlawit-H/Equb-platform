import request from 'supertest';
import app from '../app.js';

describe('Auth', () => {
  it('POST /api/v1/auth/register - returns 400 when body is missing', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({});
    expect(res.status).toBe(400);
  });

  it('POST /api/v1/auth/login - returns 400 when body is missing', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({});
    expect(res.status).toBe(400);
  });
});
