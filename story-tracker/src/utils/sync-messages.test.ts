import { describe, expect, it } from 'vitest';
import { formatSyncResultMessage } from './sync-messages';

const base = { pushedLatest: false };

describe('formatSyncResultMessage', () => {
  it('reports synced count with server verification', () => {
    expect(
      formatSyncResultMessage({ ...base, synced: 3, failed: 0, localCount: 3, serverCount: 3 }),
    ).toContain('3/3 truyện');
    expect(
      formatSyncResultMessage({ ...base, synced: 3, failed: 0, localCount: 3, serverCount: 3 }),
    ).toContain('Cloud hiện có 3 truyện');
  });

  it('reports partial failure', () => {
    const msg = formatSyncResultMessage({
      ...base,
      synced: 2,
      failed: 1,
      localCount: 3,
      serverCount: 2,
      error: 'API down',
      pushedLatest: true,
    });
    expect(msg).toContain('2/3 truyện');
    expect(msg).toContain('1 lỗi');
  });

  it('reports empty local history', () => {
    expect(
      formatSyncResultMessage({ ...base, synced: 0, failed: 0, localCount: 0, serverCount: 0 }),
    ).toContain('Chưa có truyện nào trên máy');
  });

  it('reports kong outage', () => {
    expect(
      formatSyncResultMessage({
        ...base,
        synced: 0,
        failed: 2,
        localCount: 2,
        serverCount: -1,
        error: 'Personal OS API is down (Kong has no healthy backend)',
      }),
    ).toContain('503');
  });
});
