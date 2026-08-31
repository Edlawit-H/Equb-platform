import request from 'supertest';
import app from '../app.js';

describe('Notifications API', () => {
  it('GET /api/v1/notifications - requires authentication', async () => {
    const res = await request(app).get('/api/v1/notifications');
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/notifications/unread - requires authentication', async () => {
    const res = await request(app).get('/api/v1/notifications/unread');
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/notifications - requires authentication', async () => {
    const res = await request(app).post('/api/v1/notifications').send({
      title: 'Test',
      message: 'Test message',
    });
    expect(res.status).toBe(401);
  });

  it('PATCH /api/v1/notifications/read-all - requires authentication', async () => {
    const res = await request(app).patch('/api/v1/notifications/read-all');
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/notifications/send - requires authentication', async () => {
    const res = await request(app).post('/api/v1/notifications/send').send({
      title: 'Broadcast',
      message: 'Broadcast message',
      broadcast: true,
    });
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/notifications/settings - requires authentication', async () => {
    const res = await request(app).get('/api/v1/notifications/settings');
    expect(res.status).toBe(401);
  });
});
