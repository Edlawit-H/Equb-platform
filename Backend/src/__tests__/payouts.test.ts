import request from 'supertest';
import app from '../app.js';

describe('Payouts', () => {
  it('GET /api/v1/payouts - returns 401 without token', async () => {
    const res = await request(app).get('/api/v1/payouts');
    expect(res.status).toBe(401);
  });
});
