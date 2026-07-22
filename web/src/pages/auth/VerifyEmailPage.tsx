import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Icon } from '../../components/Icon';
import { openMailbox } from '../../lib/mailbox';
import { useToast } from '../../components/Toast';
import { resendVerification } from '../../api/auth';
import starstruck from '../../assets/eugene/starstruck.png';

// Also the landing page for a failed GET /auth/verify — the API 302-redirects
// here with ?error=invalid (missing/invalid/expired token) or ?error=server.
export function VerifyEmailPage() {
  const navigate = useNavigate();
  const toast = useToast();
  const [params] = useSearchParams();
  const email = (useLocation().state as { email?: string } | null)?.email;
  const linkError = params.get('error');

  async function onResend() {
    if (!email) {
      navigate('/register');
      return;
    }
    try {
      await resendVerification(email);
      toast.success('Verification link sent again.');
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
        mascot={starstruck}
        headline={
          linkError ? (
            <>
              That link
              <br />
              didn't work.
            </>
          ) : (
            <>
              One quick step
              <br />
              and you're in.
            </>
          )
        }
        body={
          linkError
            ? "Verification links expire after a while, or may already have been used — request a fresh one."
            : 'We verify every .edu so the map stays students-only.'
        }
      />
      <div className="auth-form-side">
        <div className="auth-form auth-center">
          <div className={linkError ? 'auth-hero-check warn' : 'auth-hero-check'}>
            <Icon name={linkError ? 'info' : 'mailCheck'} size={42} strokeWidth={1.8} />
          </div>
          <h1 className="auth-h" style={{ marginTop: 22 }}>
            {linkError ? 'Link expired or invalid' : 'Verify your email'}
          </h1>
          <p className="auth-sub">
            {linkError ? (
              linkError === 'server' ? (
                'Something went wrong verifying that link on our end.'
              ) : (
                "That verification link is no longer valid — it may have expired or already been used."
              )
            ) : (
              <>
                We sent a verification link to
                <br />
                <strong style={{ color: 'var(--text)', fontWeight: 600 }}>{email || 'your school email'}</strong>. Click
                it to activate your account — you'll need to verify before you can log in.
              </>
            )}
          </p>
          <button
            className="btn btn-primary btn-lg btn-block"
            style={{ marginTop: 26 }}
            onClick={linkError ? onResend : () => openMailbox(email || '')}
          >
            {linkError ? 'Resend verification link' : 'Open email app'}
          </button>
          {!linkError && (
            <div style={{ marginTop: 20, fontSize: 13.5, color: 'var(--text-2)', fontWeight: 500 }}>
              Didn't get it?{' '}
              <button type="button" className="link" onClick={onResend}>
                Resend verification link
              </button>
            </div>
          )}
          <div className="auth-alt">
            <button type="button" className="link" onClick={() => navigate('/login')}>
              Back to log in
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
