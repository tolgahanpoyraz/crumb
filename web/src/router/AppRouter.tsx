/* web/src/router/AppRouter.tsx */

import React from 'react';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';
import { Navbar } from '../components/layout/Navbar.js';
import { ProtectedRoute } from '../components/layout/ProtectedRoute.js';

// Page Imports
import { FeedPage } from '../pages/FeedPage.js';
import { LoginPage } from '../pages/LoginPage.js';
import { RegisterPage } from '../pages/RegisterPage.js';
import { ForgotPasswordPage } from '../pages/ForgotPasswordPage.js';
import { ResetPasswordPage } from '../pages/ResetPasswordPage.js';
import { CreatePostPage } from '../pages/CreatePostPage.js';
import { ProfilePage } from '../pages/ProfilePage.js';

// Common Layout Wrapper
const AppLayout: React.FC = () => {
  return (
    <>
      <Navbar />
      <main className="container" style={mainStyle}>
        <Outlet />
      </main>
      <footer style={footerStyle}>
        <div className="container">
          <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
            &copy; {new Date().getFullYear()} FreeFood Network. COP4331 Project.
          </p>
        </div>
      </footer>
    </>
  );
};

export const AppRouter: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AppLayout />}>
          {/* Public Routes */}
          <Route index element={<FeedPage />} />
          <Route path="login" element={<LoginPage />} />
          <Route path="register" element={<RegisterPage />} />
          <Route path="forgot-password" element={<ForgotPasswordPage />} />
          <Route path="reset-password" element={<ResetPasswordPage />} />

          {/* Protected Member Routes */}
          <Route
            path="create-post"
            element={
              <ProtectedRoute>
                <CreatePostPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="profile"
            element={
              <ProtectedRoute>
                <ProfilePage />
              </ProtectedRoute>
            }
          />

          {/* Catch-all 404 Route */}
          <Route path="*" element={<NotFound />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
};

// Simple inline 404 View
const NotFound: React.FC = () => {
  return (
    <div style={{ textAlign: 'center', padding: '60px 0', flex: 1 }} className="fade-in">
      <span style={{ fontSize: '3rem' }}>🔍</span>
      <h2 style={{ marginTop: '16px', marginBottom: '8px' }}>Page Not Found</h2>
      <p style={{ marginBottom: '24px' }}>We couldn't find the page you are looking for.</p>
      <Link to="/" style={goHomeLinkStyle}>Go back to the Live Feed</Link>
    </div>
  );
};

import { Link } from 'react-router-dom';

const goHomeLinkStyle: React.CSSProperties = {
  display: 'inline-block',
  background: 'var(--color-primary)',
  color: '#fff',
  padding: '10px 20px',
  borderRadius: 'var(--border-radius-sm)',
  fontWeight: 600,
  textDecoration: 'none',
};

const mainStyle: React.CSSProperties = {
  flex: 1,
  padding: '32px 24px 64px',
  display: 'flex',
  flexDirection: 'column',
};

const footerStyle: React.CSSProperties = {
  width: '100%',
  padding: '24px 0',
  borderTop: '1px solid var(--border-light)',
  textAlign: 'center',
  background: 'var(--bg-surface)',
};
