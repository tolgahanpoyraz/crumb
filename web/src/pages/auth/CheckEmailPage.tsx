import { useLocation, useNavigate } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Icon } from '../../components/Icon';
import { openMailbox } from '../../lib/mailbox';
import { useToast } from '../../components/Toast';
import { forgotPassword } from '../../api/auth';
import starstruck from '../../assets/eugene/starstruck.png';

export function CheckEmailPage() {
  const navigate = useNavigate();
  const toast = useToast();
  const email = (useLocation().state as { email?: string } | null)?.email;

  async function onResend() {
    if (!email) {
      navigate('/forgot-password');
      return;
    }
    try {
      await forgotPassword(email);
      toast.success('Reset link sent again.');
    } catch {
      toast.error('Could not resend right now.');
    }
  }

  return (
    <div className="auth-screen">
      <BrandPanel
        variant="coral"
        showLogo
        showFoot
        align="between"
        mascot={starstruck}
        headline="Eugene's on it."
        body="The link expires in an hour, so don't wander too far."
      />
      <div className="auth-form-side">
        <div className="auth-form auth-center">
          <div className="auth-hero-check">
            <Icon name="mailCheck" size={42} strokeWidth={1.8} />
          </div>
          <h1 className="auth-h" style={{ marginTop: 22 }}>
            Check your email
          </h1>
          <p className="auth-sub">
            We sent a reset link to
            <br />
            <strong style={{ color: 'var(--text)', fontWeight: 600 }}>{email || 'your school email'}</strong>. Tap it
            to set a new password.
          </p>
          <button className="btn btn-primary btn-lg btn-block" style={{ marginTop: 26 }} onClick={() => openMailbox(email || '')}>
            Open email app
          </button>
          <div style={{ marginTop: 20, fontSize: 13.5, color: 'var(--text-2)', fontWeight: 500 }}>
            Didn't get it?{' '}
            <button type="button" className="link" onClick={onResend}>
              Resend link
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
