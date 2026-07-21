import { useEffect, useState, type ReactNode } from 'react';
import { Icon } from '../../components/Icon';
import { getFeed } from '../../api/posts';

interface BrandPanelProps {
  variant: 'coral' | 'green';
  headline: ReactNode;
  body?: ReactNode;
  showLogo?: boolean;
  showFoot?: boolean;
  features?: { icon: 'pin' | 'bell' | 'check'; text: string }[];
  align?: 'between' | 'center';
  mascotSize?: 'lg' | 'sm';
  headlineSize?: number;
  mascot?: string;
}

// The gradient marketing panel shared by every auth screen. Eugene (the panda
// mascot) art fills the circular slot; each screen passes its own sticker.
export function BrandPanel({
  variant,
  headline,
  body,
  showLogo = false,
  showFoot = false,
  features,
  align = 'center',
  mascotSize = 'lg',
  headlineSize,
  mascot,
}: BrandPanelProps) {
  const [openSpots, setOpenSpots] = useState<number | null>(null);

  useEffect(() => {
    if (!showFoot) return;
    let cancelled = false;
    getFeed()
      .then((res) => {
        if (cancelled) return;
        setOpenSpots(res.posts.filter((p) => p.status !== 'gone').length);
      })
      .catch(() => {
        // Auth pages must render offline — silently keep the fallback copy.
      });
    return () => {
      cancelled = true;
    };
  }, [showFoot]);

  const blobs =
    variant === 'coral' ? (
      <>
        <span className="brand-blob" style={{ top: -80, right: -80, width: 320, height: 320, background: 'rgba(255,255,255,.09)' }} />
        <span className="brand-blob" style={{ bottom: -120, left: -60, width: 340, height: 340, background: 'rgba(255,255,255,.08)' }} />
      </>
    ) : (
      <>
        <span className="brand-blob" style={{ top: -90, left: -70, width: 320, height: 320, background: 'rgba(255,255,255,.09)' }} />
        <span className="brand-blob" style={{ bottom: -110, right: -70, width: 340, height: 340, background: 'rgba(255,255,255,.08)' }} />
      </>
    );

  const mascotEl = (
    <div className={`brand-mascot ${mascotSize === 'sm' ? 'sm' : ''}`}>
      <div className="slot">
        {mascot && <img className="mascot-img" src={mascot} alt="Eugene the panda" />}
      </div>
    </div>
  );

  return (
    <aside className={`brand-panel ${variant}`} style={align === 'between' ? { justifyContent: 'space-between' } : undefined}>
      {blobs}

      {showLogo && (
        <div className="brand-top">
          <span className="brand-logo-sm">
            <Icon name="crumb" size={26} stroke="#fff" strokeWidth={1.8} />
          </span>
          <span className="brand-word">crumb</span>
        </div>
      )}

      <div style={{ position: 'relative' }}>
        {mascotEl}
        <div className="brand-headline" style={headlineSize ? { fontSize: headlineSize } : undefined}>
          {headline}
        </div>
        {body && <div className="brand-body">{body}</div>}

        {features && (
          <div className="brand-features">
            {features.map((f, i) => (
              <div className="brand-feature" key={i}>
                <span className="ic">
                  <Icon name={f.icon} size={18} stroke="#fff" strokeWidth={2.2} />
                </span>
                <span className="tx">{f.text}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {showFoot && (
        <div className="brand-foot">
          {openSpots !== null && openSpots >= 1
            ? `Built for UCF · ${openSpots} free spots active right now`
            : "Built for UCF · Free food, before it's gone."}
        </div>
      )}
    </aside>
  );
}
