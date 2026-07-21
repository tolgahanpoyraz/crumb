import { useNavigate, useSearchParams } from 'react-router-dom';
import { BrandPanel } from './BrandPanel';
import { Icon } from '../../components/Icon';
import munching from '../../assets/eugene/munching.png';

// Landing page for a successful GET /auth/verify — the API 302-redirects here
// with an optional ?name= for the greeting. Below the phone breakpoint this
// swaps to the design's dedicated mobile comp (green header band + overlap
// sheet) instead of hiding the brand panel like other auth screens.
export function EmailVerifiedPage() {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const name = params.get('name');
  const greeting = name ? `You're in, ${name}.` : "You're all set.";

  return (
    <>
      <div className="auth-screen verified-desktop">
        <BrandPanel
          variant="green"
          showLogo
          showFoot
          align="between"
          mascot={munching}
          headline={greeting}
          body="Your @ucf.edu is verified — that's how we keep the map students-only."
        />
        <div className="auth-form-side">
          <div className="auth-form auth-center">
            <div className="auth-hero-check lg">
              <Icon name="badgeCheck" size={46} strokeWidth={1.9} />
            </div>
            <h1 className="auth-h" style={{ marginTop: 22 }}>
              Email verified
            </h1>
            <p className="auth-sub">Your account's all set. Jump in and see what's fresh near you.</p>
            <button
              className="btn btn-primary btn-lg btn-block"
              style={{ marginTop: 26 }}
              onClick={() => navigate('/login')}
            >
              Log in to Crumb
            </button>
          </div>
        </div>
      </div>

      <div className="verified-mobile">
        <div className="verified-mobile-band">
          <div className="brand-mascot sm">
            <div className="slot">
              <img className="mascot-img" src={munching} alt="Eugene the panda" />
            </div>
          </div>
          <div className="verified-mobile-greeting">{greeting}</div>
        </div>
        <div className="verified-mobile-sheet">
          <div className="auth-hero-check md">
            <Icon name="badgeCheck" size={40} strokeWidth={1.9} />
          </div>
          <h1 className="auth-h" style={{ marginTop: 20, fontSize: 24 }}>
            Email verified
          </h1>
          <p className="auth-sub">Your account's all set. Jump in and see what's fresh near you.</p>
          <button
            className="btn btn-primary btn-lg btn-block"
            style={{ marginTop: 26 }}
            onClick={() => navigate('/login')}
          >
            Log in to Crumb
          </button>
          <div className="verified-mobile-note">You can close this tab and head back to the app.</div>
        </div>
      </div>
    </>
  );
}
