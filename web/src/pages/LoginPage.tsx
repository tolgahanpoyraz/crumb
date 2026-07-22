/* web/src/pages/LoginPage.tsx */

import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.js';

export const LoginPage: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Get the redirect path from location state, default to Feed
  const from = (location.state as any)?.from?.pathname || '/';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in all fields.');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to sign in. Please verify your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={containerStyle} className="fade-in">
      <div className="glass-panel" style={cardStyle}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <span style={{ fontSize: '2.5rem' }}>🔐</span>
          <h2 style={{ marginTop: '12px', marginBottom: '8px' }}>Welcome Back</h2>
          <p style={{ fontSize: '0.9rem' }}>Sign in to vote or report free food spots.</p>
        </div>

        {error && (
          <div style={errorBannerStyle}>
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} style={formStyle}>
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
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <label style={labelStyle}>Password</label>
              <Link to="/forgot-password" style={forgotPasswordLinkStyle}>Forgot?</Link>
            </div>
            <input
              type="password"
              className="glass-input"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
              required
            />
          </div>

          <button type="submit" className="btn-primary" style={{ width: '100%', marginTop: '12px' }} disabled={loading}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div style={footerStyle}>
          <p style={{ fontSize: '0.85rem' }}>
            New to FreeFood? <Link to="/register" style={{ fontWeight: 600 }}>Create an account</Link>
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

const forgotPasswordLinkStyle: React.CSSProperties = {
  fontSize: '0.8rem',
  fontWeight: 500,
  color: 'var(--color-primary-text)',
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

const footerStyle: React.CSSProperties = {
  marginTop: '28px',
  textAlign: 'center',
};
