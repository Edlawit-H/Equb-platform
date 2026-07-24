import request from 'supertest';
import app from '../app.js';

describe('Contributions', () => {
  it('GET /api/v1/contributions - requires authentication', async () => {
    const res = await request(app).get('/api/v1/contributions');
    expect(res.status).toBe(401);
  });
});
