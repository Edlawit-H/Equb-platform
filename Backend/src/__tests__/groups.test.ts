import request from 'supertest';
import app from '../app.js';

describe('Groups', () => {
  it('POST /api/v1/groups - returns 401 without token', async () => {
    const res = await request(app).post('/api/v1/groups').send({});
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/groups - returns 401 without token', async () => {
    const res = await request(app).get('/api/v1/groups');
    expect(res.status).toBe(401);
  });
});
