/* web/src/components/layout/Navbar.tsx */

import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.js';

export const Navbar: React.FC = () => {
  const { isAuthenticated, user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header style={headerStyle}>
      <div className="container" style={navContainerStyle}>
        {/* Brand Logo */}
        <Link to="/" style={logoStyle}>
          <span style={logoEmojiStyle}>🍔</span>
          <span style={logoTextStyle}>Free<span style={{ color: 'var(--color-primary)' }}>Food</span></span>
        </Link>

        {/* Navigation Links */}
        <nav style={navLinksStyle}>
          <Link to="/" style={linkStyle}>Live Feed</Link>
          
          {isAuthenticated ? (
            <>
              <Link to="/create-post" style={createPostButtonStyle}>
                <span>+</span> Post Food
              </Link>
              <Link to="/profile" style={profileLinkStyle}>
                <span style={avatarPlaceholderStyle}>
                  {user?.email[0].toUpperCase()}
                </span>
                <span className="nav-email" style={emailTextStyle}>{user?.email}</span>
              </Link>
              <button onClick={handleLogout} className="btn-secondary" style={logoutButtonStyle}>
                Logout
              </button>
            </>
          ) : (
            <div style={authButtonsContainerStyle}>
              <Link to="/login" style={linkStyle}>Login</Link>
              <Link to="/register" className="btn-primary" style={registerButtonStyle}>
                Sign Up
              </Link>
            </div>
          )}
        </nav>
      </div>
    </header>
  );
};

// Inline Layout Styles for high-fidelity scaffold
const headerStyle: React.CSSProperties = {
  position: 'sticky',
  top: 0,
  zIndex: 100,
  width: '100%',
  height: '70px',
  background: 'hsla(222, 47%, 7%, 0.75)',
  backdropFilter: 'var(--backdrop-blur)',
  WebkitBackdropFilter: 'var(--backdrop-blur)',
  borderBottom: '1px solid var(--border-light)',
  display: 'flex',
  alignItems: 'center',
};

const navContainerStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
};

const logoStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '8px',
  textDecoration: 'none',
};

const logoEmojiStyle: React.CSSProperties = {
  fontSize: '1.8rem',
};

const logoTextStyle: React.CSSProperties = {
  fontSize: '1.4rem',
  fontWeight: 800,
  color: 'var(--text-primary)',
  letterSpacing: '-0.5px',
};

const navLinksStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '24px',
};

const linkStyle: React.CSSProperties = {
  color: 'var(--text-secondary)',
  fontWeight: 500,
  fontSize: '0.95rem',
  transition: 'color var(--transition-fast)',
  textDecoration: 'none',
};

const createPostButtonStyle: React.CSSProperties = {
  display: 'inline-flex',
  alignItems: 'center',
  gap: '6px',
  background: 'linear-gradient(135deg, var(--color-primary), hsl(12, 100%, 55%))',
  color: '#fff',
  fontWeight: 600,
  fontSize: '0.9rem',
  padding: '8px 16px',
  borderRadius: '99px',
  textDecoration: 'none',
  boxShadow: 'var(--shadow-glow)',
  transition: 'transform var(--transition-fast), filter var(--transition-fast)',
};

const profileLinkStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  textDecoration: 'none',
  color: 'var(--text-primary)',
};

const avatarPlaceholderStyle: React.CSSProperties = {
  width: '32px',
  height: '32px',
  borderRadius: '50%',
  background: 'linear-gradient(135deg, var(--color-secondary), var(--color-primary))',
  color: '#fff',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  fontWeight: 700,
  fontSize: '0.9rem',
  boxShadow: '0 0 10px rgba(168, 85, 247, 0.3)',
};

const emailTextStyle: React.CSSProperties = {
  fontSize: '0.9rem',
  fontWeight: 500,
  maxWidth: '150px',
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
};

const authButtonsContainerStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '16px',
};

const registerButtonStyle: React.CSSProperties = {
  padding: '8px 18px',
  fontSize: '0.9rem',
  borderRadius: '99px',
};

const logoutButtonStyle: React.CSSProperties = {
  padding: '6px 12px',
  fontSize: '0.85rem',
  borderRadius: 'var(--border-radius-sm)',
};
