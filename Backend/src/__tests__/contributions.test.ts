import request from 'supertest';
import app from '../app.js';

describe('Contributions', () => {
  it('POST /api/v1/contributions - returns 401 without token', async () => {
    const res = await request(app).post('/api/v1/contributions').send({});
    expect(res.status).toBe(401);
  });
});
