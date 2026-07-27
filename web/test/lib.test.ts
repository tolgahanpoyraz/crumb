import { statusFromConfidence } from '../src/lib/freshness';
import { tierProgress } from '../src/lib/reputation';
import { scorePassword } from '../src/lib/strength';

describe('web app utilities', () => {
  test('maps confidence boundary values to the expected freshness status', () => {
    expect(statusFromConfidence(0.65)).toBe('fresh');
    expect(statusFromConfidence(0.5)).toBe('likely');
    expect(statusFromConfidence(0.15)).toBe('gone');
  });

  test('calculates progress relative to the current reputation tier', () => {
    expect(tierProgress(100, 1, 150)).toEqual({
      pct: 50,
      label: '100 / 150 to Loaf',
      atTop: false,
    });
  });

  test('scores a long mixed password as very strong', () => {
    expect(scorePassword('CrumbFinder42!')).toEqual({
      score: 4,
      label: 'Very strong.',
      color: '#4FB783',
    });
  });
});
