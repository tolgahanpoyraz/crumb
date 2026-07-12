/* web/src/pages/FeedPage.tsx */

import React, { useState, useEffect } from 'react';
import { postService } from '../api/posts.js';
import { useAuth } from '../context/AuthContext.js';
import type { Post } from '../api/types.js';

// Visual fallback mock data if backend connection fails
const MOCK_POSTS: Post[] = [
  {
    id: 'mock-1',
    foodName: 'Voodoo Doughnuts (Assorted)',
    type: 'baked-goods',
    dietaryTags: ['vegetarian'],
    location: { id: 'student-union', name: 'Student Union', latitude: 28.6016695, longitude: -81.2005277 },
    author: 'mock-user-1',
    status: 'fresh',
    confidence: 0.94,
    tallies: { present: 6, gone: 0 },
    expiresAt: new Date(Date.now() + 3600000 * 2).toISOString(),
    createdAt: new Date().toISOString(),
  },
  {
    id: 'mock-2',
    foodName: 'Leftover Panera Catering (Wraps & Salad)',
    type: 'meal',
    dietaryTags: ['vegetarian'],
    location: { id: 'l3harris-engineering-center', name: 'L3Harris Engineering Center (HEC)', latitude: 28.6006421, longitude: -81.1977141 },
    author: 'mock-user-2',
    status: 'likely',
    confidence: 0.72,
    tallies: { present: 4, gone: 1 },
    expiresAt: new Date(Date.now() + 3600000 * 1).toISOString(),
    createdAt: new Date(Date.now() - 1800000).toISOString(),
  },
  {
    id: 'mock-3',
    foodName: "Cold Pizza (Domino's Pepperoni)",
    type: 'pizza',
    dietaryTags: [],
    location: { id: 'engineering-i', name: 'Engineering I', latitude: 28.6014069, longitude: -81.198508 },
    author: 'mock-user-3',
    status: 'fading',
    confidence: 0.38,
    tallies: { present: 1, gone: 2 },
    expiresAt: new Date(Date.now() + 1800000).toISOString(),
    createdAt: new Date(Date.now() - 7200000).toISOString(),
  },
];

export const FeedPage: React.FC = () => {
  const { isAuthenticated } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFallback, setIsFallback] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [voteErrors, setVoteErrors] = useState<Record<string, string>>({});
  const [votingIds, setVotingIds] = useState<Record<string, boolean>>({});

  useEffect(() => {
    fetchFeed();
  }, []);

  const fetchFeed = async () => {
    setLoading(true);
    try {
      const data = await postService.getFeed();
      setPosts(data.posts);
      setIsFallback(false);
    } catch (err) {
      console.warn('Backend API connection failed, using high-fidelity mock data. Error:', err);
      setPosts(MOCK_POSTS);
      setIsFallback(true);
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (postId: string, voteType: 'present' | 'gone') => {
    if (!isAuthenticated) {
      setVoteErrors(prev => ({
        ...prev,
        [postId]: 'Please sign in to vote!'
      }));
      setTimeout(() => {
        setVoteErrors(prev => {
          const updated = { ...prev };
          delete updated[postId];
          return updated;
        });
      }, 3000);
      return;
    }

    setVotingIds(prev => ({ ...prev, [postId]: true }));
    try {
      if (isFallback) {
        // Mock client vote update for demonstration
        setPosts(prevPosts =>
          prevPosts.map(post => {
            if (post.id === postId) {
              const updatedTallies = { ...post.tallies };
              if (voteType === 'present') {
                updatedTallies.present += 1;
              } else {
                updatedTallies.gone += 1;
              }
              const totalVotes = updatedTallies.present + updatedTallies.gone;
              const newConfidence = updatedTallies.present / totalVotes;

              let newStatus: Post['status'] = 'gone';
              if (newConfidence >= 0.8) newStatus = 'fresh';
              else if (newConfidence >= 0.5) newStatus = 'likely';
              else if (newConfidence >= 0.1) newStatus = 'fading';

              return {
                ...post,
                tallies: updatedTallies,
                confidence: newConfidence,
                status: newStatus,
              };
            }
            return post;
          })
        );
      } else {
        // Real backend call
        const response = await postService.votePost(postId, voteType);
        setPosts(prevPosts =>
          prevPosts.map(post => {
            if (post.id === postId) {
              return {
                ...post,
                confidence: response.confidence,
                status: response.status,
                tallies: response.tallies,
              };
            }
            return post;
          })
        );
      }
    } catch (err: any) {
      setVoteErrors(prev => ({
        ...prev,
        [postId]: err.message || 'Already voted or failed to record vote'
      }));
      setTimeout(() => {
        setVoteErrors(prev => {
          const updated = { ...prev };
          delete updated[postId];
          return updated;
        });
      }, 3000);
    } finally {
      setVotingIds(prev => ({ ...prev, [postId]: false }));
    }
  };

  // Filter posts based on search query. 
  const filteredPosts = posts.filter(post => {
    const query = searchQuery.toLowerCase();
    const matchesFoodName = post.foodName.toLowerCase().includes(query);
    const matchesLocation = post.location.name.toLowerCase().includes(query);
    const matchesTag = post.dietaryTags.some(tag => tag.toLowerCase().includes(query));
    return matchesFoodName || matchesLocation || matchesTag;
  });

  const getStatusBadgeClass = (status: Post['status']) => {
    switch (status) {
      case 'fresh': return 'badge badge-fresh';
      case 'likely': return 'badge badge-likely';
      case 'fading': return 'badge badge-fading';
      case 'gone': return 'badge badge-gone';
      default: return 'badge';
    }
  };

  const getStatusColor = (status: Post['status']) => {
    switch (status) {
      case 'fresh': return 'var(--status-fresh)';
      case 'likely': return 'var(--status-likely)';
      case 'fading': return 'var(--status-fading)';
      case 'gone': return 'var(--status-gone)';
      default: return 'var(--text-secondary)';
    }
  };

  const getStatusText = (status: Post['status']) => {
    switch (status) {
      case 'fresh': return 'Fresh / Highly Active';
      case 'likely': return 'Likely Still There';
      case 'fading': return 'Fading / Might Be Gone';
      case 'gone': return 'All Gone / Expired';
      default: return status;
    }
  };

  // Build the main body up front 
  let feedBody: React.ReactNode;

  if (loading) {
    feedBody = (
      <div style={loadingContainerStyle}>
        <div className="spinner" style={spinnerStyle}></div>
        <p>Loading live feed...</p>
      </div>
    );
  } else if (filteredPosts.length === 0) {
    feedBody = (
      <div style={emptyStateCardStyle} className="glass-panel">
        <span style={{ fontSize: '3rem' }}>🍃</span>
        <h3 style={{ marginTop: '16px', marginBottom: '8px' }}>No Food Spotted</h3>
        <p>We couldn't find any active reports matching your search. Why not report some?</p>
      </div>
    );
  } else {
    feedBody = (
      <div style={postsGridStyle}>
        {filteredPosts.map(post => {
          const confidencePercent = Math.round((post.confidence ?? 0.5) * 100);
          const statusColor = getStatusColor(post.status);

          return (
            <article key={post.id} className="glass-panel" style={cardOverrideStyle}>
              {/* Badge Header */}
              <div style={cardHeaderStyle}>
                <span className={getStatusBadgeClass(post.status)}>
                  {post.status}
                </span>
                <span style={timeStyle}>
                  {new Date(post.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>

              {/* Title & Location */}
              <div style={{ flex: 1, margin: '12px 0' }}>
                <h3 style={foodTitleStyle}>{post.foodName}</h3>
                <p style={locationStyle}>📍 {post.location.name}</p>
              </div>

              {/* Dietary Tags */}
              <div style={tagsContainerStyle}>
                {post.dietaryTags.map((tag, idx) => (
                  <span key={idx} style={tagStyle}>
                    #{tag}
                  </span>
                ))}
              </div>

              {/* Confidence Meter Section */}
              <div style={confidenceSectionStyle}>
                <div style={confidenceHeaderStyle}>
                  <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                    Confidence Level
                  </span>
                  <span style={{ fontSize: '0.9rem', fontWeight: 700, color: statusColor }}>
                    {confidencePercent}%
                  </span>
                </div>

                {/* Meter Track */}
                <div style={meterTrackStyle}>
                  <div style={{
                    height: '100%',
                    width: `${confidencePercent}%`,
                    backgroundColor: statusColor,
                    borderRadius: '99px',
                    boxShadow: `0 0 10px ${statusColor}40`,
                    transition: 'width var(--transition-slow) ease-out, background-color var(--transition-normal)'
                  }} />
                </div>
                <div style={meterLabelsStyle}>
                  <span>{getStatusText(post.status)}</span>
                  <span>({post.tallies.present} / {post.tallies.present + post.tallies.gone} votes)</span>
                </div>
              </div>

              {/* Card Action Buttons (Voting) */}
              <div style={actionRowStyle}>
                <button
                  disabled={votingIds[post.id]}
                  onClick={() => handleVote(post.id, 'present')}
                  className="btn-secondary"
                  style={{
                    ...voteButtonStyle,
                    borderColor: 'rgba(16, 185, 129, 0.2)',
                    background: 'rgba(16, 185, 129, 0.04)'
                  }}
                >
                  👍 Still Here
                </button>
                <button
                  disabled={votingIds[post.id]}
                  onClick={() => handleVote(post.id, 'gone')}
                  className="btn-secondary"
                  style={{
                    ...voteButtonStyle,
                    borderColor: 'rgba(239, 68, 68, 0.2)',
                    background: 'rgba(239, 68, 68, 0.04)'
                  }}
                >
                  👎 All Gone
                </button>
              </div>

              {voteErrors[post.id] && (
                <p style={voteErrorStyle}>{voteErrors[post.id]}</p>
              )}
            </article>
          );
        })}
      </div>
    );
  }

  return (
    <div className="fade-in" style={feedPageStyle}>
      {/* Header section */}
      <div style={feedHeaderContainerStyle}>
        <div>
          <h1 style={{ marginBottom: '8px', fontSize: '2.2rem' }}>Active Food Feed</h1>
          <p>Confidence-ranked real-time reports of free grub on campus.</p>
        </div>

        {/* Search Bar */}
        <div style={searchWrapperStyle}>
          <input
            type="text"
            placeholder="Search food, halls, or tags..."
            className="glass-input"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ paddingLeft: '40px' }}
          />
          <span style={searchIconStyle}>🔍</span>
        </div>
      </div>

      {isFallback && (
        <div style={apiNoticeBannerStyle}>
          <span>⚠️</span>
          <span><strong>Offline Demo Mode:</strong> Backend server is not running or unreachable at port 5001. Showing interactive mock data.</span>
          <button onClick={fetchFeed} style={retryButtonStyle}>Retry</button>
        </div>
      )}

      {feedBody}
    </div>
  );
};

// Styles for components
const feedPageStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  width: '100%',
};

const feedHeaderContainerStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
  marginBottom: '32px',
  flexWrap: 'wrap',
  gap: '16px',
};

const searchWrapperStyle: React.CSSProperties = {
  position: 'relative',
  width: '100%',
  maxWidth: '360px',
};

const searchIconStyle: React.CSSProperties = {
  position: 'absolute',
  left: '12px',
  top: '50%',
  transform: 'translateY(-50%)',
  fontSize: '1rem',
  pointerEvents: 'none',
  opacity: 0.7,
};

const apiNoticeBannerStyle: React.CSSProperties = {
  background: 'hsla(45, 93%, 47%, 0.15)',
  border: '1px solid hsla(45, 93%, 47%, 0.3)',
  color: 'var(--status-likely)',
  padding: '12px 20px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '24px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  flexWrap: 'wrap',
  gap: '12px',
  fontSize: '0.9rem',
};

const retryButtonStyle: React.CSSProperties = {
  background: 'var(--status-likely)',
  border: 'none',
  color: '#000',
  padding: '4px 12px',
  borderRadius: '4px',
  fontWeight: '600',
  cursor: 'pointer',
  fontSize: '0.8rem',
};

const loadingContainerStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '80px 0',
  gap: '16px',
  color: 'var(--text-secondary)',
};

const spinnerStyle: React.CSSProperties = {
  width: '32px',
  height: '32px',
  border: '3px solid var(--border-light)',
  borderTop: '3px solid var(--color-primary)',
  borderRadius: '50%',
  animation: 'spin 1s linear infinite',
};

const emptyStateCardStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '64px',
  textAlign: 'center',
};

const postsGridStyle: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))',
  gap: '24px',
  width: '100%',
};

const cardOverrideStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  padding: '24px',
  height: '100%',
  minHeight: '320px',
};

const cardHeaderStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
  marginBottom: '16px',
};

const timeStyle: React.CSSProperties = {
  fontSize: '0.8rem',
  color: 'var(--text-muted)',
  fontWeight: 500,
};

const foodTitleStyle: React.CSSProperties = {
  fontSize: '1.25rem',
  fontWeight: 700,
  color: 'var(--text-primary)',
  lineHeight: 1.3,
  marginBottom: '6px',
};

const locationStyle: React.CSSProperties = {
  fontSize: '0.9rem',
  color: 'var(--text-secondary)',
};

const tagsContainerStyle: React.CSSProperties = {
  display: 'flex',
  flexWrap: 'wrap',
  gap: '8px',
  margin: '12px 0 20px',
};

const tagStyle: React.CSSProperties = {
  fontSize: '0.75rem',
  fontWeight: 600,
  color: 'var(--text-muted)',
  background: 'hsla(217, 30%, 90%, 0.04)',
  padding: '3px 8px',
  borderRadius: '4px',
  border: '1px solid var(--border-light)',
};

const confidenceSectionStyle: React.CSSProperties = {
  marginBottom: '20px',
  display: 'flex',
  flexDirection: 'column',
  gap: '6px',
};

const confidenceHeaderStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
};

const meterTrackStyle: React.CSSProperties = {
  height: '8px',
  width: '100%',
  backgroundColor: 'var(--bg-input)',
  borderRadius: '99px',
  overflow: 'hidden',
  border: '1px solid var(--border-light)',
};

const meterLabelsStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  fontSize: '0.75rem',
  color: 'var(--text-muted)',
};

const actionRowStyle: React.CSSProperties = {
  display: 'flex',
  gap: '12px',
  marginTop: 'auto',
};

const voteButtonStyle: React.CSSProperties = {
  flex: 1,
  padding: '10px',
  fontSize: '0.85rem',
  fontWeight: 600,
  borderRadius: 'var(--border-radius-sm)',
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'center',
  gap: '6px',
};

const voteErrorStyle: React.CSSProperties = {
  fontSize: '0.75rem',
  color: 'var(--status-gone)',
  textAlign: 'center',
  marginTop: '8px',
  fontWeight: 500,
};