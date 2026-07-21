/* web/src/pages/RegisterPage.tsx */

import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.js';
import { authService } from '../api/auth.js';

export const RegisterPage: React.FC = () => {
  const { register } = useAuth();

  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [registeredEmail, setRegisteredEmail] = useState<string | null>(null);
  const [resendStatus, setResendStatus] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!displayName || !email || !password || !confirmPassword) {
      setError('Please fill in all fields.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      await register(displayName, email, password);
      // Backend registers user as unverified and sends verification email
      setRegisteredEmail(email);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Registration failed. The email may already be in use.');
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (!registeredEmail) return;
    setLoading(true);
    setResendStatus(null);
    try {
      const response = await authService.resendVerification(registeredEmail);
      setResendStatus(response.message || 'Verification email resent successfully.');
    } catch (err: any) {
      setResendStatus(err.message || 'Failed to resend. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // If successfully registered, show the email check screen
  if (registeredEmail) {
    return (
      <div style={containerStyle} className="fade-in">
        <div className="glass-panel" style={cardStyle}>
          <div style={{ textAlign: 'center' }}>
            <span style={{ fontSize: '3rem' }}>✉️</span>
            <h2 style={{ marginTop: '16px', marginBottom: '12px' }}>Verify Your Email</h2>
            <p style={{ marginBottom: '24px' }}>
              We have sent a verification link to <strong style={{ color: 'var(--text-primary)' }}>{registeredEmail}</strong>.
              Please check your inbox (and spam folder) and verify your account to log in.
            </p>

            {resendStatus && (
              <div style={infoBannerStyle}>
                <span>ℹ️</span>
                <span>{resendStatus}</span>
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <button onClick={handleResend} className="btn-primary" disabled={loading}>
                {loading ? 'Sending...' : 'Resend Verification Email'}
              </button>
              <Link to="/login" className="btn-secondary">
                Go to Login
              </Link>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={containerStyle} className="fade-in">
      <div className="glass-panel" style={cardStyle}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <span style={{ fontSize: '2.5rem' }}>🌱</span>
          <h2 style={{ marginTop: '12px', marginBottom: '8px' }}>Create Account</h2>
          <p style={{ fontSize: '0.9rem' }}>Join to share and vote on free food listings.</p>
        </div>

        {error && (
          <div style={errorBannerStyle}>
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} style={formStyle}>
          <div style={formGroupStyle}>
            <label style={labelStyle}>Display Name</label>
            <input
              type="text"
              className="glass-input"
              placeholder="e.g. Knightro"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>University Email</label>
            <input
              type="email"
              className="glass-input"
              placeholder="you@university.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>Password</label>
            <input
              type="password"
              className="glass-input"
              placeholder="Min. 8 characters"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <div style={formGroupStyle}>
            <label style={labelStyle}>Confirm Password</label>
            <input
              type="password"
              className="glass-input"
              placeholder="Re-enter password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <button type="submit" className="btn-primary" style={{ width: '100%', marginTop: '12px' }} disabled={loading}>
            {loading ? 'Creating Account...' : 'Sign Up'}
          </button>
        </form>

        <div style={footerStyle}>
          <p style={{ fontSize: '0.85rem' }}>
            Already have an account? <Link to="/login" style={{ fontWeight: 600 }}>Sign In</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

// Inline Styles for high-fidelity scaffold
const containerStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '40px 0',
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

const infoBannerStyle: React.CSSProperties = {
  background: 'var(--color-warning-bg)',
  border: '1px solid var(--color-warning-border)',
  color: 'var(--color-warning-text)',
  padding: '12px 16px',
  borderRadius: 'var(--border-radius-sm)',
  marginBottom: '20px',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  fontSize: '0.85rem',
  textAlign: 'left',
};

const footerStyle: React.CSSProperties = {
  marginTop: '28px',
  textAlign: 'center',
};