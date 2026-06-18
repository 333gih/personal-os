import { describe, it, expect } from 'vitest';
import { isAdminFromToken, userFromToken } from './jwt';

function makeToken(payload: Record<string, unknown>): string {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = btoa(JSON.stringify(payload));
  return `${header}.${body}.signature`;
}

describe('jwt helpers', () => {
  it('detects admin claim', () => {
    const token = makeToken({ admin: true, user_id: '1', email: 'a@b.com', exp: 9999999999 });
    expect(isAdminFromToken(token)).toBe(true);
  });

  it('rejects non-admin internal users', () => {
    const token = makeToken({ admin: false, user_id: '1', email: 'a@b.com', exp: 9999999999 });
    expect(isAdminFromToken(token)).toBe(false);
  });

  it('extracts user from token', () => {
    const token = makeToken({
      user_id: 'abc',
      email: 'user@example.com',
      name: 'Test User',
      exp: 9999999999,
    });
    const user = userFromToken(token);
    expect(user.id).toBe('abc');
    expect(user.email).toBe('user@example.com');
    expect(user.name).toBe('Test User');
  });
});
