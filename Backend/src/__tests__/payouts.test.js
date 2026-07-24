import request from 'supertest';
import app from '../app.js';

describe('Payouts', () => {
  it('GET /api/v1/payouts - requires authentication', async () => {
    const res = await request(app).get('/api/v1/payouts');
    expect(res.status).toBe(401);
  });
});
