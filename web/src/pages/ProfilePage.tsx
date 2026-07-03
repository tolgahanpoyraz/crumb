/* web/src/pages/ProfilePage.tsx */

import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext.js';
import { authService } from '../api/auth.js';

export const ProfilePage: React.FC = () => {
  const { user, refreshUser } = useAuth();
  
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentPassword || !newPassword || !confirmPassword) {
      setError('Please fill in all fields.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('New passwords do not match.');
      return;
    }

    if (newPassword.length < 6) {
      setError('New password must be at least 6 characters long.');
      return;
    }

    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      const response = await authService.changePassword({
        currentPassword,
        newPassword,
      });

      // Update stored token with the new one issued by the server
      localStorage.setItem('auth_token', response.token);
      
      setSuccess('Password updated successfully! Other sessions have been signed out.');
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      
      // Refresh context profile details
      await refreshUser();
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to update password. Please check your current password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={containerStyle} className="fade-in">
      <div style={profileGridStyle}>
        
        {/* Left Side: Account Info Card */}
        <section className="glass-panel" style={cardStyle}>
          <div style={profileHeaderStyle}>
            <div style={avatarStyle}>
              {user?.email[0].toUpperCase()}
            </div>
            <h2 style={{ marginTop: '16px' }}>My Account</h2>
            <p style={{ fontSize: '0.85rem' }}>Member of FreeFood Network</p>
          </div>

          <div style={infoListStyle}>
            <div style={infoRowStyle}>
              <span style={infoLabelStyle}>Email Address</span>
              <span style={infoValueStyle}>{user?.email}</span>
            </div>
            
            <div style={infoRowStyle}>
              <span style={infoLabelStyle}>Account ID</span>
              <span style={infoValueStyleCode}>{user?.id}</span>
            </div>

            <div style={infoRowStyle}>
              <span style={infoLabelStyle}>Status</span>
              <span style={user?.verified ? verifiedBadgeStyle : unverifiedBadgeStyle}>
                {user?.verified ? 'Verified Email' : 'Pending Verification'}
              </span>
            </div>
          </div>
        </section>

        {/* Right Side: Change Password Card */}
        <section className="glass-panel" style={cardStyle}>
          <h2 style={{ marginBottom: '8px' }}>Security Settings</h2>
          <p style={{ marginBottom: '24px', fontSize: '0.9rem' }}>Update your password to secure your account.</p>

          {error && (
            <div style={errorBannerStyle}>
              <span>⚠️</span>
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div style={successBannerStyle}>
              <span>✓</span>
              <span>{success}</span>
            </div>
          )}

          <form onSubmit={handlePasswordChange} style={formStyle}>
            <div style={formGroupStyle}>
              <label style={labelStyle}>Current Password</label>
              <input
                type="password"
                className="glass-input"
                placeholder="Enter current password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                disabled={loading}
                required
              />
            </div>

            <div style={formGroupStyle}>
              <label style={labelStyle}>New Password</label>
              <input
                type="password"
                className="glass-input"
                placeholder="Min. 6 characters"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                disabled={loading}
                required
              />
            </div>

            <div style={formGroupStyle}>
              <label style={labelStyle}>Confirm New Password</label>
              <input
                type="password"
                className="glass-input"
                placeholder="Re-enter new password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                disabled={loading}
                required
              />
            </div>

            <button type="submit" className="btn-primary" style={{ marginTop: '8px' }} disabled={loading}>
              {loading ? 'Updating Password...' : 'Update Password'}
            </button>
          </form>
        </section>

      </div>
    </div>
  );
};

// Inline Layout Styles
const containerStyle: React.CSSProperties = {
  padding: '10px 0 40px',
  width: '100%',
};

const profileGridStyle: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
  gap: '32px',
  width: '100%',
};

const cardStyle: React.CSSProperties = {
  padding: '40px',
  display: 'flex',
  flexDirection: 'column',
};

const profileHeaderStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  textAlign: 'center',
  marginBottom: '32px',
};

const avatarStyle: React.CSSProperties = {
  width: '80px',
  height: '80px',
  borderRadius: '50%',
  background: 'linear-gradient(135deg, var(--color-secondary), var(--color-primary))',
  color: '#fff',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  fontWeight: 800,
  fontSize: '2.5rem',
  boxShadow: '0 8px 30px rgba(168, 85, 247, 0.4)',
};

const infoListStyle: React.CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  gap: '20px',
};

const infoRowStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
  paddingBottom: '12px',
  borderBottom: '1px solid var(--border-light)',
};

const infoLabelStyle: React.CSSProperties = {
  fontSize: '0.85rem',
  fontWeight: 600,
  color: 'var(--text-secondary)',
};

const infoValueStyle: React.CSSProperties = {
  fontSize: '0.9rem',
  color: 'var(--text-primary)',
  fontWeight: 500,
};

const infoValueStyleCode: React.CSSProperties = {
  fontSize: '0.8rem',
  fontFamily: 'ui-monospace, monospace',
  color: 'var(--text-muted)',
};

const verifiedBadgeStyle: React.CSSProperties = {
  fontSize: '0.75rem',
  fontWeight: 700,
  color: 'var(--status-fresh)',
  background: 'var(--status-fresh-glow)',
  border: '1px solid hsla(142, 76%, 45%, 0.3)',
  padding: '3px 8px',
  borderRadius: '4px',
};

const unverifiedBadgeStyle: React.CSSProperties = {
  fontSize: '0.75rem',
  fontWeight: 700,
  color: 'var(--status-likely)',
  background: 'var(--status-likely-glow)',
  border: '1px solid hsla(45, 93%, 47%, 0.3)',
  padding: '3px 8px',
  borderRadius: '4px',
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

const successBannerStyle: React.CSSProperties = {
  background: 'rgba(16, 185, 129, 0.12)',
  border: '1px solid rgba(16, 185, 129, 0.25)',
  color: 'var(--status-fresh)',
  padding: '12px 16px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '20px',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  fontSize: '0.85rem',
};
