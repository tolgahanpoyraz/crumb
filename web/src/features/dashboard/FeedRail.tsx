import type { ReactNode } from 'react';
import type { Post, VoteType } from '../../api/types';
import { FoodCard } from './FoodCard';
import { FilterChips, type PrimaryFilter } from './FilterChips';
import { Icon } from '../../components/Icon';
import { EugeneCycle } from '../../components/EugeneCycle';
import type { DietaryTag } from '../../api/types';

interface EmptyState {
  title: string;
  body: string;
}

interface FeedRailProps {
  title: string;
  countLine: ReactNode;
  search: string;
  onSearch: (v: string) => void;
  filter: PrimaryFilter;
  onFilter: (f: PrimaryFilter) => void;
  dietary: DietaryTag[];
  onDietary: (t: DietaryTag[]) => void;
  posts: Post[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onVote: (id: string, type: VoteType) => void;
  votedSet: Set<string>;
  distances: Map<string, number>;
  mineView: boolean;
  currentUserId: string;
  now: number;
  empty: EmptyState;
  onPost: () => void;
  loading: boolean;
  error: string | null;
  onRetry: () => void;
}

export function FeedRail(props: FeedRailProps) {
  const { posts, selectedId, distances, now } = props;

  return (
    <div className="feed-rail">
      <div className="feed-head">
        <div className="feed-title">{props.title}</div>
        <div className="feed-count">{props.countLine}</div>

        <div className="search">
          <Icon name="search" size={16} strokeWidth={2.2} />
          <input
            type="search"
            placeholder="Search free food"
            value={props.search}
            onChange={(e) => props.onSearch(e.target.value)}
            aria-label="Search free food"
          />
        </div>

        <FilterChips
          filter={props.filter}
          onFilter={props.onFilter}
          dietary={props.dietary}
          onDietary={props.onDietary}
        />
      </div>

      {props.loading && posts.length === 0 ? (
        <div className="empty-state">
          <div className="spinner dark" style={{ width: 26, height: 26 }} />
          <div className="b" style={{ marginTop: 14 }}>
            Loading fresh drops…
          </div>
        </div>
      ) : props.error && posts.length === 0 ? (
        <div className="empty-state">
          <div className="icon">
            <Icon name="info" size={36} stroke="#e0b7a6" strokeWidth={1.8} />
          </div>
          <div className="t">Couldn't load the feed</div>
          <div className="b">{props.error}</div>
          <button className="btn btn-secondary" style={{ height: 44, padding: '0 20px', marginTop: 18 }} onClick={props.onRetry}>
            Try again
          </button>
        </div>
      ) : posts.length === 0 ? (
        <div className="empty-state">
          <EugeneCycle imgClassName="empty-mascot" start="crying" />
          <div className="t">{props.empty.title}</div>
          <div className="b">{props.empty.body}</div>
          <div className="b eugene-caption">
            {props.mineView
              ? 'Eugene ate the last one. Post your first drop?'
              : 'Eugene ate the last one. Post the next drop?'}
          </div>
          <button className="btn btn-primary" style={{ height: 46, padding: '0 20px', marginTop: 18 }} onClick={props.onPost}>
            <Icon name="plus" size={16} stroke="#fff" strokeWidth={2.6} />
            Post free food
          </button>
        </div>
      ) : (
        <div className="feed-list cw-scroll">
          {posts.map((post) => (
            <FoodCard
              key={post._id}
              post={post}
              selected={post._id === selectedId}
              distanceMi={distances.get(post._id)}
              now={now}
              onSelect={() => props.onSelect(post._id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
