import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Field } from '../../components/Field';
import { Icon } from '../../components/Icon';
import { PasswordStrength } from '../../components/PasswordStrength';
import { register } from '../../api/auth';
import { ApiError } from '../../api/client';
import waving from '../../assets/eugene/waving.png';

const EDU_RE = /@[^\s@]+\.edu$/i;

export function RegisterPage() {
  const navigate = useNavigate();
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [agreed, setAgreed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEdu = EDU_RE.test(email.trim());

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    setError(null);

    if (!isEdu) {
      setError('Use your school .edu email address.');
      return;
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }
    if (!agreed) {
      setError('Please agree to the Community Guidelines.');
      return;
    }

    setBusy(true);
    try {
      await register(displayName.trim(), email.trim(), password);
      navigate('/verify-email', { state: { email: email.trim() } });
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        setError('That email is already in use.');
      } else {
        setError(err instanceof Error ? err.message : 'Could not create your account');
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="auth-screen">
      <div className="auth-form-side">
        <form className="auth-form wide" onSubmit={onSubmit}>
          <h1 className="auth-h">Join Crumb</h1>
          <p className="auth-sub">Share leftovers, snag free food, waste less.</p>

          <div className="field-label" style={{ marginTop: 26 }}>
            What should we call you?
          </div>
          <Field icon="user" small>
            <input
              type="text"
              autoComplete="name"
              placeholder="Your display name"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              maxLength={100}
              required
            />
          </Field>

          <div className="field-label" style={{ marginTop: 16 }}>
            School email
          </div>
          <Field
            icon="mail"
            small
            trailing={isEdu ? <span className="badge-verified">.edu verified</span> : undefined}
          >
            <input
              type="email"
              autoComplete="email"
              placeholder="you@ucf.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Field>

          <div className="field-label" style={{ marginTop: 16 }}>
            Password
          </div>
          <Field icon="lock" small>
            <input
              type="password"
              autoComplete="new-password"
              placeholder="Create a password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </Field>
          <PasswordStrength password={password} />

          <button
            type="button"
            className={`checkbox ${agreed ? 'checked' : ''}`}
            style={{ marginTop: 18, background: 'none', border: 'none', textAlign: 'left', padding: 0 }}
            onClick={() => setAgreed((a) => !a)}
            aria-pressed={agreed}
          >
            <span className="box">{agreed && <Icon name="check" size={12} stroke="#fff" strokeWidth={3} />}</span>
            <span className="label">
              I agree to the <span className="link">Community Guidelines</span> — real food, real locations, no
              waste.
            </span>
          </button>

          {error && (
            <div className="form-error">
              <Icon name="info" size={16} strokeWidth={2} />
              {error}
            </div>
          )}

          <button className="btn btn-primary btn-lg btn-block" style={{ marginTop: 20 }} disabled={busy}>
            {busy ? <span className="spinner" /> : 'Create account'}
          </button>

          <div className="auth-alt">
            Already have an account?{' '}
            <button type="button" className="link" onClick={() => navigate('/login')}>
              Log in
            </button>
          </div>
        </form>
      </div>

      <BrandPanel
        variant="green"
        mascotSize="sm"
        headlineSize={30}
        mascot={waving}
        headline={
          <>
            Every meal shared
            <br />
            is one less wasted.
          </>
        }
        body="Eugene's saving you a seat."
        features={[
          { icon: 'pin', text: 'See free food pinned across campus' },
          { icon: 'bell', text: 'Get pinged when fresh food drops nearby' },
          { icon: 'check', text: 'Vote to keep the map honest' },
        ]}
      />
    </main>
  );
}
