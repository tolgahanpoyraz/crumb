import type { PostStatus } from '../api/types';
import { STATUS_META, meterPosition } from '../lib/freshness';

interface FreshnessMeterProps {
  status: PostStatus;
  confidence: number;
  votes: number;
}

export function FreshnessMeter({ status, confidence, votes }: FreshnessMeterProps) {
  const pos = meterPosition(confidence);
  const color = STATUS_META[status].dot;
  return (
    <div className="meter">
      <div className="meter-head">
        <div className="t">Freshness</div>
        <div className="v">
          {votes} vote{votes === 1 ? '' : 's'}
        </div>
      </div>
      <div className="meter-bar">
        <div className="meter-thumb" style={{ left: `${pos}%`, borderColor: color }} />
      </div>
      <div className="meter-scale">
        <span>GONE</span>
        <span>FADING</span>
        <span>LIKELY</span>
        <span style={{ color: '#2f9d63' }}>FRESH</span>
      </div>
    </div>
  );
}
