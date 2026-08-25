import { describe, expect, it } from 'vitest';
import { mapOneFootballStatus } from './onefootball_status_mapper';

describe('mapOneFootballStatus', () => {
  it('maps the two confirmed real-world values', () => {
    expect(mapOneFootballStatus('PRE_MATCH')).toBe('scheduled');
    expect(mapOneFootballStatus('FULL_TIME')).toBe('finished');
  });

  it('maps live-play periods to live', () => {
    for (const period of ['FIRST_HALF', 'SECOND_HALF', 'EXTRA_TIME', 'PENALTY_SHOOTOUT', 'LIVE']) {
      expect(mapOneFootballStatus(period)).toBe('live');
    }
  });

  it('maps halftime, postponed, cancelled and suspended variants', () => {
    expect(mapOneFootballStatus('HALF_TIME')).toBe('halftime');
    expect(mapOneFootballStatus('POSTPONED')).toBe('postponed');
    expect(mapOneFootballStatus('CANCELLED')).toBe('cancelled');
    expect(mapOneFootballStatus('CANCELED')).toBe('cancelled');
    expect(mapOneFootballStatus('SUSPENDED')).toBe('suspended');
    expect(mapOneFootballStatus('ABANDONED')).toBe('suspended');
  });

  it('falls back to unknown for anything unrecognized', () => {
    expect(mapOneFootballStatus('SOMETHING_NEW')).toBe('unknown');
    expect(mapOneFootballStatus('')).toBe('unknown');
  });
});
