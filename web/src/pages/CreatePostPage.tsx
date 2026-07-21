/* web/src/pages/CreatePostPage.tsx */

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { postService } from '../api/posts.js';
import { POST_TYPES } from '../api/types.js';
import type { PostType } from '../api/types.js';

export const CreatePostPage: React.FC = () => {
  const navigate = useNavigate();

  const [foodName, setFoodName] = useState('');
  const [type, setType] = useState<PostType | ''>('');
  const [location, setLocation] = useState('');
  const [badgeInput, setBadgeInput] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [uploadStatus, setUploadStatus] = useState<string | null>(null);

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!foodName || !type || !location) {
      setError('Food Name, Type, and Location are required fields.');
      return;
    }

    setError(null);
    setLoading(true);
    setUploadStatus(null);

    // Parse comma-separated tags into an array. The backend only accepts a
    // fixed set of dietary tags, so anything else will 400 - that's fine,
    // the backend error message will explain it.
    const dietaryTags = badgeInput
      .split(',')
      .map(tag => tag.trim().toLowerCase())
      .filter(tag => tag.length > 0) as any;

    try {
      let imageKey: string | undefined = undefined;

      // Handle Image upload if a file was selected
      if (imageFile) {
        setUploadStatus('Requesting secure upload authorization...');
        try {
          // 1. Get S3 presigned URL
          const { url, key } = await postService.getUploadUrl();
          imageKey = key;

          setUploadStatus('Uploading image directly to cloud storage...');
          // 2. PUT binary directly to S3
          await postService.uploadImageToS3(url, imageFile);
          setUploadStatus('Upload complete!');
        } catch (uploadErr: any) {
          console.error('S3 Upload failed:', uploadErr);

          if (uploadErr.status === 503 || uploadErr.message?.includes('configured')) {
            // S3 not set up on backend (503 response)
            const proceedWithoutImage = window.confirm(
              'Image uploads are not configured on this server. Would you like to post this without an image?'
            );
            if (!proceedWithoutImage) {
              setLoading(false);
              setUploadStatus(null);
              return;
            }
          } else {
            const proceedWithoutImage = window.confirm(
              'Image upload failed. Would you like to post this without an image anyway?'
            );
            if (!proceedWithoutImage) {
              setLoading(false);
              setUploadStatus(null);
              return;
            }
          }
          imageKey = undefined; // Don't submit key
        }
      }

      setUploadStatus('Recording post details...');
      // 3. Create the post
      await postService.createPost({
        foodName,
        type,
        dietaryTags,
        location,
        imageKey,
      });

      navigate('/');
    } catch (err: any) {
      console.error('Post creation failed:', err);
      setError(err.message || 'Failed to create food post. Please verify fields.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={containerStyle} className="fade-in">
      <div className="glass-panel" style={cardStyle}>
        <div style={{ marginBottom: '28px' }}>
          <h2 style={{ marginBottom: '6px' }}>🍕 Share Free Food</h2>
          <p style={{ fontSize: '0.9rem' }}>Spot some leftovers? Spread the word to hungry students.</p>
        </div>

        {error && (
          <div style={errorBannerStyle}>
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        {uploadStatus && (
          <div style={statusBannerStyle}>
            <div className="spinner" style={smallSpinnerStyle}></div>
            <span>{uploadStatus}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} style={formStyle}>
          <div style={formGroupStyle}>
            <label style={labelStyle}>What food is there?</label>
            <input
              type="text"
              className="glass-input"
              placeholder="e.g. Leftover Catering Sandwiches"
              value={foodName}
              onChange={(e) => setFoodName(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>What kind of food?</label>
            <select
              className="glass-input"
              value={type}
              onChange={(e) => setType(e.target.value as PostType)}
              disabled={loading}
              required
            >
              <option value="" disabled>Select a category</option>
              {POST_TYPES.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>Where is it located?</label>
            <input
              type="text"
              className="glass-input"
              placeholder="e.g. Student Union, Room 204"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>Tags (comma-separated)</label>
            <input
              type="text"
              className="glass-input"
              placeholder="e.g. vegetarian, halal, vegan"
              value={badgeInput}
              onChange={(e) => setBadgeInput(e.target.value)}
              disabled={loading}
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>Upload Food Photo (optional)</label>
            <div style={uploadBoxStyle}>
              {imagePreview ? (
                <div style={previewContainerStyle}>
                  <img src={imagePreview} alt="Preview" style={previewImageStyle} />
                  <button
                    type="button"
                    onClick={() => { setImageFile(null); setImagePreview(null); }}
                    style={removeImageButtonStyle}
                  >
                    Change Image
                  </button>
                </div>
              ) : (
                <label style={fileLabelStyle}>
                  <span style={{ fontSize: '2rem', marginBottom: '8px' }}>📷</span>
                  <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Click to select photo</span>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>JPEG, PNG up to 5MB</span>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageChange}
                    style={{ display: 'none' }}
                    disabled={loading}
                  />
                </label>
              )}
            </div>
          </div>

          <div style={buttonRowStyle}>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => navigate('/')}
              disabled={loading}
              style={{ flex: 1 }}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary"
              disabled={loading}
              style={{ flex: 2 }}
            >
              {loading ? 'Submitting...' : 'Post Listing'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Inline Layout Styles
const containerStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '20px 0 40px',
  flex: 1,
};

const cardStyle: React.CSSProperties = {
  width: '100%',
  maxWidth: 'var(--max-width-form)',
  padding: '40px',
};

const formStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  gap: '20px',
};

const formGroupStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  gap: '8px',
};

const labelStyle: React.CSSProperties = {
  fontSize: '0.85rem',
  fontWeight: 600,
  color: 'var(--text-secondary)',
};

const uploadBoxStyle: React.CSSProperties = {
  border: '2px dashed var(--border-light)',
  borderRadius: 'var(--border-radius-sm)',
  background: 'var(--bg-input)',
  overflow: 'hidden',
  transition: 'border-color var(--transition-fast)',
};

const fileLabelStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '30px 20px',
  cursor: 'pointer',
  textAlign: 'center',
  width: '100%',
};

const previewContainerStyle: React.CSSProperties = {
  position: 'relative',
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  padding: '16px',
};

const previewImageStyle: React.CSSProperties = {
  maxWidth: '100%',
  maxHeight: '200px',
  borderRadius: '4px',
  objectFit: 'cover',
  marginBottom: '12px',
};

const removeImageButtonStyle: React.CSSProperties = {
  background: 'var(--bg-chip)',
  border: '1px solid var(--border-light)',
  color: 'var(--text-primary)',
  padding: '4px 12px',
  borderRadius: '4px',
  cursor: 'pointer',
  fontSize: '0.8rem',
  fontWeight: 600,
};

const buttonRowStyle: React.CSSProperties = {
  display: 'flex',
  gap: '16px',
  marginTop: '12px',
};

const errorBannerStyle: React.CSSProperties = {
  background: 'var(--color-danger-bg)',
  border: '1px solid var(--color-danger-border)',
  color: 'var(--color-danger)',
  padding: '12px 16px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '20px',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  fontSize: '0.85rem',
};

const statusBannerStyle: React.CSSProperties = {
  background: 'var(--bg-chip)',
  border: '1px solid var(--border-light)',
  color: 'var(--text-secondary)',
  padding: '12px 16px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '20px',
  display: 'flex',
  alignItems: 'center',
  gap: '12px',
  fontSize: '0.85rem',
};

const smallSpinnerStyle: React.CSSProperties = {
  width: '18px',
  height: '18px',
  border: '2px solid var(--border-light)',
  borderTop: '2px solid var(--color-primary)',
  borderRadius: '50%',
  animation: 'spin 1s linear infinite',
};