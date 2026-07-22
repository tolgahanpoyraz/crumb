import { useState, type FormEvent } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Field, PasswordInput } from '../../components/Field';
import { Icon } from '../../components/Icon';
import { PasswordStrength } from '../../components/PasswordStrength';
import { resetPassword } from '../../api/auth';
import { useToast } from '../../components/Toast';
import cheering from '../../assets/eugene/cheering.png';

export function ResetPasswordPage() {
  const navigate = useNavigate();
  const toast = useToast();
  const [params] = useSearchParams();
  const token = params.get('token');

  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const matches = confirm.length > 0 && confirm === password;

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    setError(null);

    if (!token) {
      setError('This reset link is missing its token. Request a new one.');
      return;
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      setError('Passwords do not match.');
      return;
    }

    setBusy(true);
    try {
      await resetPassword(token, password);
      toast.success('Password reset. Please log in.');
      navigate('/login', { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not reset password');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="auth-screen">
      <BrandPanel
        variant="green"
        headlineSize={32}
        mascot={cheering}
        headline={
          <>
            Almost there —
            <br />
            pick a new one.
          </>
        }
        body="Make it something fresh you'll actually remember. New password, same Eugene."
      />
      <div className="auth-form-side">
        <form className="auth-form" onSubmit={onSubmit}>
          <h1 className="auth-h">New password</h1>
          <p className="auth-sub">Choose a password you don't use anywhere else.</p>

          <div className="field-label" style={{ marginTop: 26 }}>
            New password
          </div>
          <PasswordInput
            autoComplete="new-password"
            placeholder="Create a new password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <PasswordStrength password={password} />

          <div className="field-label" style={{ marginTop: 18 }}>
            Confirm new password
          </div>
          <Field
            icon="lock"
            trailing={matches ? <Icon name="check" size={16} stroke="#4FB783" strokeWidth={2.6} /> : undefined}
          >
            <input
              type="password"
              autoComplete="new-password"
              placeholder="Re-enter new password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
            />
          </Field>

          {error && (
            <div className="form-error">
              <Icon name="info" size={16} strokeWidth={2} />
              {error}
            </div>
          )}

          <button className="btn btn-primary btn-lg btn-block" style={{ marginTop: 24 }} disabled={busy}>
            {busy ? <span className="spinner" /> : 'Reset password & log in'}
          </button>
        </form>
      </div>
    </main>
  );
}
