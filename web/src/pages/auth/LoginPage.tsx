import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Field, PasswordInput } from '../../components/Field';
import { Icon } from '../../components/Icon';
import { useAuth } from '../../auth/AuthContext';
import { useToast } from '../../components/Toast';
import { ApiError } from '../../api/client';
import { resendVerification } from '../../api/auth';
import winking from '../../assets/eugene/winking.png';

export function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const toast = useToast();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [unverified, setUnverified] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    setUnverified(false);
    try {
      await login(email.trim(), password);
      navigate('/', { replace: true });
    } catch (err) {
      if (err instanceof ApiError && err.status === 403) {
        setUnverified(true);
      } else {
        setError(err instanceof Error ? err.message : 'Could not log in');
      }
    } finally {
      setBusy(false);
    }
  }

  async function onResend() {
    try {
      await resendVerification(email.trim());
      toast.success('Verification link sent — check your inbox.');
    } catch {
      toast.error('Could not resend right now.');
    }
  }

  return (
    <main className="auth-screen">
      <BrandPanel
        variant="coral"
        showLogo
        showFoot
        align="between"
        mascot={winking}
        headline={
          <>
            Free food on campus,
            <br />
            before it's gone.
          </>
        }
        body="Students post leftover meals the moment they spot them. Grab what's near you. Eugene already knows where the good stuff is."
      />

      <div className="auth-form-side">
        <form className="auth-form" onSubmit={onSubmit}>
          <h1 className="auth-h">Welcome back</h1>
          <p className="auth-sub">Log in to see what's fresh near you.</p>

          {unverified && (
            <div className="banner-warn" style={{ marginTop: 18 }}>
              <Icon name="mail" size={18} strokeWidth={2} />
              <div className="flex-1">
                <div className="b-title">Verify your email to log in</div>
                <div className="b-body">
                  Check your inbox for the link —{' '}
                  <button type="button" className="link" onClick={onResend}>
                    resend verification link
                  </button>
                  .
                </div>
              </div>
            </div>
          )}

          <div className="field-label" style={{ marginTop: 28 }}>
            School email
          </div>
          <Field icon="mail">
            <input
              type="email"
              autoComplete="email"
              placeholder="you@ucf.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Field>

          <div className="label-row">
            <span>Password</span>
            <button type="button" className="forgot-link" onClick={() => navigate('/forgot-password')}>
              Forgot?
            </button>
          </div>
          <PasswordInput
            autoComplete="current-password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {error && (
            <div className="form-error">
              <Icon name="info" size={16} strokeWidth={2} />
              {error}
            </div>
          )}

          <button className="btn btn-primary btn-lg btn-block" style={{ marginTop: 24 }} disabled={busy}>
            {busy ? <span className="spinner" /> : 'Log in'}
          </button>

          <div className="auth-alt">
            New to Crumb?{' '}
            <button type="button" className="link" onClick={() => navigate('/register')}>
              Create an account
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
