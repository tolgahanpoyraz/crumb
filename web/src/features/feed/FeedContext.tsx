import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import * as postsApi from '../../api/posts';
import { getLocations } from '../../api/locations';
import { ApiError } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import type { CampusLocation, CreatePostRequest, Post, VoteType } from '../../api/types';

const VOTED_KEY_PREFIX = 'crumb.voted.';
const POLL_MS = 45000;

interface FeedContextValue {
  posts: Post[];
  locations: CampusLocation[];
  loading: boolean;
  error: string | null;
  voted: Set<string>;
  refresh: () => Promise<void>;
  createPost: (data: CreatePostRequest, image?: Blob | null) => Promise<Post>;
  vote: (postId: string, type: VoteType) => Promise<void>;
  removePost: (postId: string) => Promise<void>;
}

const FeedContext = createContext<FeedContextValue | null>(null);

function loadVoted(key: string): Set<string> {
  try {
    const raw = localStorage.getItem(key);
    return new Set(raw ? (JSON.parse(raw) as string[]) : []);
  } catch {
    return new Set();
  }
}

export function FeedProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const votedKey = `${VOTED_KEY_PREFIX}${user?.id ?? 'anon'}`;
  const [posts, setPosts] = useState<Post[]>([]);
  const [locations, setLocations] = useState<CampusLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [voted, setVoted] = useState<Set<string>>(() => loadVoted(votedKey));

  // Re-derive the voted set when the logged-in user changes (per-account key).
  useEffect(() => {
    setVoted(loadVoted(votedKey));
  }, [votedKey]);

  const persistVoted = useCallback(
    (next: Set<string>) => {
      setVoted(next);
      localStorage.setItem(votedKey, JSON.stringify([...next]));
    },
    [votedKey],
  );

  const markVoted = useCallback(
    (postId: string) => {
      persistVoted(new Set(voted).add(postId));
    },
    [voted, persistVoted],
  );

  const refresh = useCallback(async () => {
    try {
      const { posts } = await postsApi.getFeed();
      setPosts(posts);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load the feed');
    }
  }, []);

  // Initial load: locations (static) + first feed fetch.
  useEffect(() => {
    let active = true;
    (async () => {
      setLoading(true);
      try {
        const [loc, feed] = await Promise.all([getLocations(), postsApi.getFeed()]);
        if (!active) return;
        setLocations(loc.locations);
        setPosts(feed.posts);
        setError(null);
      } catch (err) {
        if (active) setError(err instanceof Error ? err.message : 'Failed to load');
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  // Keep the feed live while the tab is visible.
  const refreshRef = useRef(refresh);
  refreshRef.current = refresh;
  useEffect(() => {
    const id = setInterval(() => {
      if (!document.hidden) refreshRef.current();
    }, POLL_MS);
    return () => clearInterval(id);
  }, []);

  const createPost = useCallback(async (data: CreatePostRequest, image?: Blob | null) => {
    let imageKey = data.imageKey;
    if (image) {
      imageKey = await postsApi.uploadPostImage(image);
    }
    const { post } = await postsApi.createPost({ ...data, imageKey });
    setPosts((prev) => [post, ...prev.filter((p) => p._id !== post._id)]);
    return post;
  }, []);

  const vote = useCallback(
    async (postId: string, type: VoteType) => {
      // Optimistic tally bump; reconcile confidence/status from the server.
      setPosts((prev) =>
        prev.map((p) =>
          p._id === postId
            ? { ...p, tallies: { ...p.tallies, [type]: p.tallies[type] + 1 } }
            : p,
        ),
      );
      try {
        const res = await postsApi.vote(postId, type);
        markVoted(postId);
        setPosts((prev) =>
          prev.map((p) =>
            p._id === postId
              ? { ...p, confidence: res.confidence, status: res.status, tallies: res.tallies }
              : p,
          ),
        );
      } catch (err) {
        // 409 = already voted (e.g. from another device): keep it marked, resync tallies.
        if (err instanceof ApiError && err.status === 409) {
          markVoted(postId);
        }
        await refresh();
        throw err;
      }
    },
    [markVoted, refresh],
  );

  // Optimistic removal so "Delete" feels immediate; on failure, refetch so the
  // post reappears if it wasn't actually deleted server-side.
  const removePost = useCallback(
    async (postId: string) => {
      setPosts((prev) => prev.filter((p) => p._id !== postId));
      try {
        await postsApi.deletePost(postId);
      } catch (err) {
        await refresh();
        throw err;
      }
    },
    [refresh],
  );

  const value = useMemo<FeedContextValue>(
    () => ({ posts, locations, loading, error, voted, refresh, createPost, vote, removePost }),
    [posts, locations, loading, error, voted, refresh, createPost, vote, removePost],
  );

  return <FeedContext.Provider value={value}>{children}</FeedContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useFeed(): FeedContextValue {
  const ctx = useContext(FeedContext);
  if (!ctx) {
    throw new Error('useFeed must be used within FeedProvider');
  }
  return ctx;
}
