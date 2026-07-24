import request from 'supertest';
import app from '../app.js';

describe('Groups', () => {
  it('GET /api/v1/groups - requires authentication', async () => {
    const res = await request(app).get('/api/v1/groups');
    expect(res.status).toBe(401);
  });
});
