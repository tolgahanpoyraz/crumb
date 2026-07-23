import { useEffect, useState } from 'react';
import { Modal } from '../../components/Modal';
import { Icon } from '../../components/Icon';
import { Avatar } from '../../components/Avatar';
import { TierBadge } from '../../components/TierBadge';
import { useAuth } from '../../auth/AuthContext';
import { getLeaderboard } from '../../api/users';
import { tierProgress, TIER_META, TIER_THRESHOLDS } from '../../lib/reputation';
import { ApiError } from '../../api/client';
import type { LeaderboardResponse, Tier } from '../../api/types';
import munching from '../../assets/eugene/munching.png';

interface LeaderboardModalProps {
  onClose: () => void;
}

export function LeaderboardModal({ onClose }: LeaderboardModalProps) {
  const [data, setData] = useState<LeaderboardResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [nonce, setNonce] = useState(0);

  useEffect(() => {
    const ctrl = new AbortController();
    setError(null);
    getLeaderboard(ctrl.signal)
      .then(setData)
      .catch((err) => {
        if (err instanceof DOMException && err.name === 'AbortError') return;
        setError(err instanceof ApiError ? err.message : 'Could not load the leaderboard.');
      });
    return () => ctrl.abort();
  }, [nonce]);

  return (
    <Modal onClose={onClose} className="leaderboard-modal" labelledBy="leaderboard-title">
      <div className="lb">
        <div className="lb-head">
          <div>
            <div className="modal-title" id="leaderboard-title">
              Top droppers
            </div>
            <div className="modal-sub">This week around campus</div>
          </div>
          <button className="icon-btn" onClick={onClose} aria-label="Close">
            <Icon name="x" size={16} strokeWidth={2.3} />
          </button>
        </div>

        {error ? (
          <div className="lb-state">
            <div className="icon">
              <Icon name="info" size={34} stroke="#e0b7a6" strokeWidth={1.8} />
            </div>
            <div className="t">Couldn't load the leaderboard</div>
            <div className="b">{error}</div>
            <button
              className="btn btn-secondary"
              style={{ height: 44, padding: '0 20px', marginTop: 18 }}
              onClick={() => setNonce((n) => n + 1)}
            >
              Try again
            </button>
          </div>
        ) : !data ? (
          <div className="lb-state">
            <div className="spinner dark" style={{ width: 26, height: 26 }} />
            <div className="b" style={{ marginTop: 14 }}>
              Counting crumbs…
            </div>
          </div>
        ) : (
          <LeaderboardBody data={data} />
        )}
      </div>
    </Modal>
  );
}

function LeaderboardBody({ data }: { data: LeaderboardResponse }) {
  const { user } = useAuth();
  const uid = user?.id;

  const reputation = user?.reputation ?? data.me.reputation;
  const tier = (user?.tier ?? data.me.tier) as Tier;
  // Right after login the auth user lacks the reputation fields (/auth/me
  // hasn't refreshed yet), so derive the next threshold instead of trusting it.
  const nextTierAt =
    user?.nextTierAt !== undefined
      ? user.nextTierAt
      : tier >= TIER_THRESHOLDS.length - 1
        ? null
        : TIER_THRESHOLDS[tier + 1];
  const progress = tierProgress(reputation, tier, nextTierAt);

  return (
    <div className="lb-body cw-scroll">
      <div className="lb-standing">
        <div className="lb-standing-top">
          <TierBadge tier={tier} />
          <div className="lb-crumbs">
            <strong>{reputation}</strong> crumbs
          </div>
        </div>

        {progress.atTop ? (
          <div className="lb-topout">
            {TIER_META[3].glyph} You've reached {TIER_META[3].name} — top of the batch.
          </div>
        ) : (
          <>
            <div className="lb-progress">
              <div className="lb-progress-fill" style={{ width: `${progress.pct}%` }} />
            </div>
            <div className="lb-progress-label">{progress.label}</div>
          </>
        )}

        <div className="lb-standing-meta">
          <strong>{data.me.weeklyPoints}</strong> this week
          {data.me.rank !== null && <> · ranked #{data.me.rank}</>}
        </div>
      </div>

      {data.entries.length === 0 ? (
        <div className="lb-state">
          <img className="lb-empty-mascot" src={munching} alt="Eugene the panda munching" />
          <div className="b">No confirmed drops this week yet — be the first.</div>
        </div>
      ) : (
        <ol className="lb-list">
          {data.entries.map((e) => (
            <li key={e.userId} className={`lb-row ${e.userId === uid ? 'me' : ''}`}>
              <span className={`lb-rank ${e.rank <= 3 ? `rank-${e.rank}` : ''}`}>{e.rank}</span>
              <Avatar name={e.displayName} avatarKey={e.avatarKey} size={34} />
              <div className="lb-who">
                <span className="lb-name">{e.displayName}</span>
                {e.tier >= 1 && <TierBadge tier={e.tier} variant="sm" />}
              </div>
              <span className="lb-points">
                <strong>{e.weeklyPoints}</strong>
              </span>
            </li>
          ))}
        </ol>
      )}

      <div className="lb-foot">Points from confirmed drops and honest votes · last 7 days</div>
    </div>
  );
}
