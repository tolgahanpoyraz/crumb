import { useCallback, useEffect, useMemo, useState } from 'react';
import { TopBar } from '../features/dashboard/TopBar';
import { FeedRail } from '../features/dashboard/FeedRail';
import { CampusMap } from '../features/dashboard/CampusMap';
import { MapboxMap } from '../features/dashboard/MapboxMap';
import { DetailPanel } from '../features/dashboard/DetailPanel';
import { PostFoodModal } from '../features/post/PostFoodModal';
import { SettingsModal } from '../features/settings/SettingsModal';
import { EugeneCelebration } from '../components/EugeneCelebration';
import type { PrimaryFilter } from '../features/dashboard/FilterChips';
import { useFeed } from '../features/feed/FeedContext';
import { useAuth } from '../auth/AuthContext';
import { useToast } from '../components/Toast';
import { useGeolocation } from '../hooks/useGeolocation';
import { useNow } from '../hooks/useNow';
import { haversineMiles } from '../lib/geo';
import { ApiError } from '../api/client';
import type { DietaryTag, VoteType } from '../api/types';

export function DashboardPage() {
  const { user, logout } = useAuth();
  const { posts, locations, loading, error, voted, vote, createPost, removePost, refresh } = useFeed();
  const toast = useToast();
  const coords = useGeolocation();
  const now = useNow(15000);

  const [filter, setFilter] = useState<PrimaryFilter>('all');
  const [dietary, setDietary] = useState<DietaryTag[]>([]);
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [postOpen, setPostOpen] = useState(false);
  const [settings, setSettings] = useState<{ open: boolean; tab: 'profile' | 'security' }>({ open: false, tab: 'profile' });
  const [celebrate, setCelebrate] = useState<{ key: number; message: string } | null>(null);
  const dismissCelebrate = useCallback(() => setCelebrate(null), []);

  const uid = user!.id;
  const mineView = filter === 'mine';
  // Real map when a Mapbox token is configured; otherwise the keyless canvas fallback.
  const mapboxToken = import.meta.env.VITE_MAPBOX_TOKEN as string | undefined;

  // Distance (mi) from the user to each post's location, when we know where they are.
  const distances = useMemo(() => {
    const map = new Map<string, number>();
    if (coords) {
      for (const p of posts) {
        map.set(p._id, haversineMiles(coords, p.location));
      }
    }
    return map;
  }, [coords, posts]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = posts.filter((p) => {
      if (filter === 'mine' && p.author !== uid) return false;
      if (filter === 'fresh' && p.status !== 'fresh') return false;
      if (dietary.length && !dietary.every((t) => p.dietaryTags.includes(t))) return false;
      if (q && !p.foodName.toLowerCase().includes(q) && !p.location.name.toLowerCase().includes(q)) return false;
      return true;
    });
    if (filter === 'nearMe' && coords) {
      list = [...list].sort((a, b) => (distances.get(a._id) ?? Infinity) - (distances.get(b._id) ?? Infinity));
    }
    return list;
  }, [posts, filter, dietary, search, uid, coords, distances]);

  const selectedPost = selectedId ? posts.find((p) => p._id === selectedId) ?? null : null;

  // Drop the selection if that post has expired out of the feed.
  useEffect(() => {
    if (selectedId && !posts.some((p) => p._id === selectedId)) {
      setSelectedId(null);
    }
  }, [posts, selectedId]);

  const mineCount = useMemo(() => posts.filter((p) => p.author === uid).length, [posts, uid]);

  async function onVote(id: string, type: VoteType) {
    try {
      await vote(id, type);
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        toast.show('You already voted on this drop.');
      } else {
        toast.error(err instanceof Error ? err.message : 'Vote failed');
      }
    }
  }

  async function onDelete() {
    if (!selectedPost) return;
    const id = selectedPost._id;
    setSelectedId(null);
    try {
      await removePost(id);
      toast.success('Drop deleted.');
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Delete failed');
    }
  }

  const empty = mineView
    ? { title: 'No drops yet', body: 'When you post free food, it stays here until it expires or gets voted gone.' }
    : posts.length === 0
      ? {
          title: 'No free food nearby',
          body: 'New drops appear here the moment someone posts. Spot something on campus? Post it to get things rolling.',
        }
      : { title: 'Nothing matches', body: 'Try clearing your filters or search to see more drops.' };

  return (
    <div className="app-shell">
      <TopBar
        user={user!}
        onPost={() => setPostOpen(true)}
        onOpenSettings={() => setSettings({ open: true, tab: 'profile' })}
        onLogout={logout}
        onHome={() => {
          setFilter('all');
          setSelectedId(null);
        }}
      />

      <main className={`app-body ${selectedPost ? 'has-selection' : ''}`}>
        <FeedRail
          title={mineView ? 'Your drops' : 'Hot & fresh right now'}
          countLine={
            mineView ? (
              mineCount === 0 ? (
                'Nothing live right now'
              ) : (
                <>
                  <span className="hi">{mineCount} live</span>
                  {mineCount === 1
                    ? ' · expires within the hour'
                    : mineCount === 2
                      ? ' · both expire within the hour'
                      : ' · all expire within the hour'}
                </>
              )
            ) : posts.length === 0 ? (
              'No spots active near campus right now'
            ) : (
              <>
                <span className="hi">{posts.length} active</span> {posts.length === 1 ? 'spot' : 'spots'} near campus
              </>
            )
          }
          search={search}
          onSearch={setSearch}
          filter={filter}
          onFilter={setFilter}
          dietary={dietary}
          onDietary={setDietary}
          posts={filtered}
          selectedId={selectedId}
          onSelect={setSelectedId}
          onVote={onVote}
          votedSet={voted}
          distances={distances}
          mineView={mineView}
          currentUserId={uid}
          now={now}
          empty={empty}
          onPost={() => setPostOpen(true)}
          loading={loading}
          error={error}
          onRetry={refresh}
        />

        <div className="map-detail">
          {mapboxToken ? (
            <MapboxMap
              posts={filtered}
              locations={locations}
              selectedId={selectedId}
              onSelect={setSelectedId}
              userCoords={coords}
              emptyText={mineView ? 'Your drops will show up here' : 'No active spots on the map yet'}
              token={mapboxToken}
            />
          ) : (
            <CampusMap
              posts={filtered}
              locations={locations}
              selectedId={selectedId}
              onSelect={setSelectedId}
              userCoords={coords}
              emptyText={mineView ? 'Your drops will show up here' : 'No active spots on the map yet'}
            />
          )}
          {selectedPost && (
            <DetailPanel
              post={selectedPost}
              mine={selectedPost.author === uid}
              voted={voted.has(selectedPost._id)}
              distanceMi={distances.get(selectedPost._id)}
              now={now}
              onClose={() => setSelectedId(null)}
              onVote={(type) => onVote(selectedPost._id, type)}
              onDelete={onDelete}
            />
          )}
          {celebrate && (
            <EugeneCelebration key={celebrate.key} message={celebrate.message} onDone={dismissCelebrate} />
          )}
        </div>
      </main>

      {postOpen && (
        <PostFoodModal
          locations={locations}
          userCoords={coords}
          onClose={() => setPostOpen(false)}
          onCreate={createPost}
          onCreated={(post) => {
            setSelectedId(post._id);
            setCelebrate({ key: Date.now(), message: 'Drop posted! Eugene salutes you.' });
          }}
          onError={() => {}}
          onNotice={(msg) => toast.show(msg)}
        />
      )}

      {settings.open && (
        <SettingsModal initialTab={settings.tab} onClose={() => setSettings((s) => ({ ...s, open: false }))} />
      )}
    </div>
  );
}
