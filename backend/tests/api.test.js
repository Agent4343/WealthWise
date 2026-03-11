// Set test environment variables before requiring any modules
process.env.NODE_ENV = 'test';
process.env.SUPABASE_URL = 'https://test.supabase.co';
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';
process.env.ANTHROPIC_API_KEY = 'test-anthropic-key';
process.env.RESEND_API_KEY = 'test-resend-key';

const request = require('supertest');
const app = require('../src/app');

describe('Health Check', () => {
  it('GET /health returns 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('WealthWise API');
    expect(res.body.timestamp).toBeDefined();
  });
});

describe('404 Handler', () => {
  it('returns 404 for unknown routes', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Route not found');
  });
});

describe('Auth Routes', () => {
  it('POST /auth/sync returns 401 without Authorization header', async () => {
    const res = await request(app).post('/auth/sync').send({});
    expect(res.status).toBe(401);
    expect(res.body.error).toBeDefined();
  });

  it('POST /auth/sync returns 401 with malformed token', async () => {
    const res = await request(app)
      .post('/auth/sync')
      .set('Authorization', 'Bearer invalid-token');
    expect(res.status).toBe(401);
  });
});

describe('Profile Routes', () => {
  it('GET /profile returns 401 without Authorization header', async () => {
    const res = await request(app).get('/profile');
    expect(res.status).toBe(401);
  });

  it('PUT /profile returns 401 without Authorization header', async () => {
    const res = await request(app).put('/profile').send({ current_age: 30 });
    expect(res.status).toBe(401);
  });
});

describe('Briefs Routes', () => {
  it('GET /briefs returns 401 without Authorization header', async () => {
    const res = await request(app).get('/briefs');
    expect(res.status).toBe(401);
  });

  it('GET /briefs/:id returns 401 without Authorization header', async () => {
    const res = await request(app).get('/briefs/some-id');
    expect(res.status).toBe(401);
  });
});

describe('Webhooks Route', () => {
  it('POST /webhooks/appstore returns 400 for missing signedPayload', async () => {
    const res = await request(app)
      .post('/webhooks/appstore')
      .set('Content-Type', 'application/json')
      .send(JSON.stringify({}));
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Missing signedPayload');
  });

  it('POST /webhooks/appstore returns 400 for invalid JWS format', async () => {
    const res = await request(app)
      .post('/webhooks/appstore')
      .set('Content-Type', 'application/json')
      .send(JSON.stringify({ signedPayload: 'not.valid' }));
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Invalid JWS format');
  });

  it('POST /webhooks/appstore returns 200 and acknowledges valid-structure payload', async () => {
    // Build a minimal JWS-like payload with valid base64url parts
    const header = Buffer.from(JSON.stringify({ alg: 'ES256' })).toString('base64url');
    const payloadData = {
      notificationType: 'SUBSCRIBED',
      subtype: null,
      data: {
        appAccountToken: '550e8400-e29b-41d4-a716-446655440000',
        signedTransactionInfo: null,
        signedRenewalInfo: null,
      },
    };
    const payloadPart = Buffer.from(JSON.stringify(payloadData)).toString('base64url');
    const signature = Buffer.from('fake-signature').toString('base64url');
    const signedPayload = `${header}.${payloadPart}.${signature}`;

    const res = await request(app)
      .post('/webhooks/appstore')
      .set('Content-Type', 'application/json')
      .send(JSON.stringify({ signedPayload }));

    // Should return 200 (acknowledge receipt) even if DB update fails in test env
    expect(res.status).toBe(200);
    expect(res.body.received).toBe(true);
  });
});
