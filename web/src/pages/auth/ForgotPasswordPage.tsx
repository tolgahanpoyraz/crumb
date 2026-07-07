import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Field } from '../../components/Field';
import { Icon } from '../../components/Icon';
import { forgotPassword } from '../../api/auth';
import { isValidEmail } from '../../lib/validation';

export function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    setError(null);

    const value = email.trim();
    // Catch malformed addresses before submitting — otherwise we'd advance to
    // check-email with a value the API rejects, and resend would 400 there.
    if (!isValidEmail(value)) {
      setError('Enter a valid email address.');
      return;
    }

    setBusy(true);
    try {
      // Resolves 200 whether or not the account exists (no enumeration).
      await forgotPassword(value);
      navigate('/check-email', { state: { email: value } });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-screen">
      <BrandPanel
        variant="coral"
        showLogo
        showFoot
        align="between"
        headline={
          <>
            Happens to
            <br />
            everyone.
          </>
        }
        body="We'll send a link to reset it. You'll be back to snagging food in a minute."
      />
      <div className="auth-form-side">
        <form className="auth-form" onSubmit={onSubmit}>
          <button type="button" className="auth-back" onClick={() => navigate('/login')}>
            <Icon name="chevronLeft" size={15} strokeWidth={2.4} />
            Back to log in
          </button>
          <h1 className="auth-h">Reset your password</h1>
          <p className="auth-sub">Enter your school email and we'll send you a reset link.</p>

          <div className="field-label" style={{ marginTop: 26 }}>
            School email
          </div>
          <Field icon="mail" error={!!error}>
            <input
              type="email"
              autoComplete="email"
              placeholder="you@ucf.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Field>

          {error && (
            <div className="form-error">
              <Icon name="info" size={16} strokeWidth={2} />
              {error}
            </div>
          )}

          <button className="btn btn-primary btn-lg btn-block" style={{ marginTop: 22 }} disabled={busy}>
            {busy ? <span className="spinner" /> : 'Send reset link'}
          </button>

          <div className="auth-alt">
            Remembered it?{' '}
            <button type="button" className="link" onClick={() => navigate('/login')}>
              Log in
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
