import type { Post, VoteType } from '../../api/types';
import { FoodPhoto } from '../../components/FoodPhoto';
import { Avatar } from '../../components/Avatar';
import { StatusBadge } from '../../components/StatusBadge';
import { TierBadge } from '../../components/TierBadge';
import { FreshnessMeter } from '../../components/FreshnessMeter';
import { Icon } from '../../components/Icon';
import { STATUS_META } from '../../lib/freshness';
import { typeLabel, dietaryLabel } from '../../lib/content';
import { relativeTime, expiresIn } from '../../lib/time';
import { formatMiles } from '../../lib/geo';

interface DetailPanelProps {
  post: Post;
  mine: boolean;
  voted: boolean;
  distanceMi?: number;
  now: number;
  onClose: () => void;
  onVote: (type: VoteType) => void;
  onDelete: () => void;
}

export function DetailPanel({ post, mine, voted, distanceMi, now, onClose, onVote, onDelete }: DetailPanelProps) {
  const votes = post.tallies.present + post.tallies.gone;
  const gone = post.status === 'gone';
  const locationLine = [post.location.name, post.locationDetail, distanceMi !== undefined ? formatMiles(distanceMi) : null]
    .filter(Boolean)
    .join(' · ');

  return (
    <aside className="detail cw-scroll" aria-label="Post details">
      <div className="detail-photo">
        <FoodPhoto imageKey={post.imageKey} type={post.type} alt={post.foodName} height={220} />
        <div className="scrim" />
        <button className="detail-close" onClick={onClose} aria-label="Close details">
          <Icon name="x" size={16} strokeWidth={2.3} />
        </button>
        <div className="detail-expiry">
          <Icon name="clock" size={13} stroke="#fff" strokeWidth={2} />
          {expiresIn(post.expiresAt, now)}
        </div>
      </div>

      <div className="detail-body">
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10 }}>
          <div className="detail-title">{post.foodName}</div>
          <StatusBadge status={post.status} />
        </div>

        {!mine && post.authorName ? (
          <div className="detail-poster" style={{ marginTop: 12 }}>
            <span className="ring">
              <Avatar name={post.authorName} avatarKey={post.authorAvatarKey} size={28} />
            </span>
            <div className="txt">
              <span>
                Posted by <strong>{post.authorName}</strong>
              </span>
              {post.authorTier !== undefined && post.authorTier >= 1 && (
                <TierBadge tier={post.authorTier} variant="sm" />
              )}
              <span>· {relativeTime(post.createdAt, now)}</span>
            </div>
          </div>
        ) : (
          !mine && (
            <div className="detail-meta" style={{ marginTop: 12, color: 'var(--text-muted)' }}>
              <Icon name="user" size={14} stroke="var(--text-muted)" strokeWidth={2} />
              Posted {relativeTime(post.createdAt, now)}
            </div>
          )
        )}

        <div className="detail-meta" style={{ marginTop: 10 }}>
          <Icon name="pin" size={15} stroke="#F0653F" strokeWidth={2} />
          {locationLine}
        </div>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10 }}>
          {mine && <span className="tag tag-mine">Your drop</span>}
          <span className="tag tag-type">{typeLabel(post.type)}</span>
          {post.dietaryTags.map((t) => (
            <span key={t} className="tag tag-diet">
              {dietaryLabel(t)}
            </span>
          ))}
        </div>

        <div style={{ marginTop: 16 }}>
          <FreshnessMeter status={post.status} confidence={post.confidence} votes={votes} />
        </div>

        {mine ? (
          <>
            <div className="tally-grid">
              <div className="tally-cell present">
                <div className="n">{post.tallies.present}</div>
                <div className="l">still here</div>
              </div>
              <div className="tally-cell gone">
                <div className="n">{post.tallies.gone}</div>
                <div className="l">gone</div>
              </div>
            </div>
            <div className="own-note">You can't vote on your own drop — the votes above are from others.</div>
            <button className="btn btn-danger" style={{ width: '100%', height: 48, marginTop: 14 }} onClick={onDelete}>
              <Icon name="trash" size={17} strokeWidth={2} />
              Delete this drop
            </button>
          </>
        ) : (
          <>
            <div className="vote-prompt">Is it still there?</div>
            <div className="vote-actions">
              <button className="vote-btn present" disabled={voted || gone} onClick={() => onVote('present')}>
                <Icon name="check" size={18} stroke="#fff" strokeWidth={2.6} />
                Still here
              </button>
              <button className="vote-btn gone" disabled={voted || gone} onClick={() => onVote('gone')}>
                <Icon name="x" size={16} strokeWidth={2.6} />
                It's gone
              </button>
            </div>
            {voted && <div className="own-note" style={{ marginTop: 12 }}>Thanks — you've voted on this drop.</div>}

            <div className="activity">
              <div className="activity-row">
                <span className="dot" style={{ background: STATUS_META.fresh.dot }} />
                <strong>{post.tallies.present}</strong>&nbsp;said still here
              </div>
              <div className="activity-row">
                <span className="dot" style={{ background: STATUS_META.gone.dot }} />
                <strong>{post.tallies.gone}</strong>&nbsp;said gone
                <span className="when">updated {relativeTime(post.updatedAt, now)}</span>
              </div>
            </div>
          </>
        )}
      </div>
    </aside>
  );
}
