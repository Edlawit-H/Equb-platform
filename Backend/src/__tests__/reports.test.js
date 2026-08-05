import request from 'supertest';
import app from '../app.js';

describe('Reports API', () => {
  it('GET /api/v1/reports/dashboard - requires authentication', async () => {
    const res = await request(app).get('/api/v1/reports/dashboard');
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/reports/user-summary - requires authentication', async () => {
    const res = await request(app).get('/api/v1/reports/user-summary');
    expect(res.status).toBe(401);
  });
});
