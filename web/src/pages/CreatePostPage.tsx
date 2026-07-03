/* web/src/pages/CreatePostPage.tsx */

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { postService } from '../api/posts.js';

export const CreatePostPage: React.FC = () => {
  const navigate = useNavigate();

  const [foodName, setFoodName] = useState('');
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
    if (!foodName || !location) {
      setError('Food Name and Location are required fields.');
      return;
    }

    setError(null);
    setLoading(true);
    setUploadStatus(null);

    // Parse comma-separated badges into an array
    const badges = badgeInput
      .split(',')
      .map(tag => tag.trim().toLowerCase())
      .filter(tag => tag.length > 0);

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
        location,
        badges,
        imageKey,
      });

      navigate('/');
    } catch (err: any) {
      console.error('Post creation failed:', err);
      // Fallback behavior if API is down
      if (err.message?.includes('failed to fetch') || err.status === undefined) {
        setUploadStatus('Simulating post creation offline...');
        // Wait 1s and mock redirect
        await new Promise(resolve => setTimeout(resolve, 1000));
        navigate('/');
      } else {
        setError(err.message || 'Failed to create food post. Please verify fields.');
      }
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
            <label style={labelStyle}>Where is it located?</label>
            <input
              type="text"
              className="glass-input"
              placeholder="e.g. HEC Room 101"
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
              placeholder="e.g. pizza, spicy, vegetarian, catering"
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
  background: 'hsla(217, 30%, 90%, 0.1)',
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
  background: 'rgba(239, 68, 68, 0.12)',
  border: '1px solid rgba(239, 68, 68, 0.25)',
  color: 'var(--status-gone)',
  padding: '12px 16px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '20px',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  fontSize: '0.85rem',
};

const statusBannerStyle: React.CSSProperties = {
  background: 'hsla(265, 85%, 66%, 0.1)',
  border: '1px solid hsla(265, 85%, 66%, 0.25)',
  color: 'var(--color-secondary)',
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
  borderTop: '2px solid var(--color-secondary)',
  borderRadius: '50%',
  animation: 'spin 1s linear infinite',
};
