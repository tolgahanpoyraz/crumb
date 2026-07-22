import { useEffect, useState } from 'react';
import cheering from '../assets/eugene/cheering.png';

interface EugeneCelebrationProps {
  message: string;
  onDone: () => void;
}

// A non-blocking Eugene pop-in shown when a drop is posted. It sits bottom-left
// over the map, never steals focus, ignores pointer events, and self-dismisses:
// spring in, hold, then fade out just before it unmounts.
export function EugeneCelebration({ message, onDone }: EugeneCelebrationProps) {
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    const fade = window.setTimeout(() => setLeaving(true), 3150);
    const done = window.setTimeout(onDone, 3500);
    return () => {
      window.clearTimeout(fade);
      window.clearTimeout(done);
    };
  }, [onDone]);

  return (
    <div className={`eugene-celebrate${leaving ? ' leaving' : ''}`} role="status" aria-live="polite">
      <img className="eugene-celebrate-img" src={cheering} alt="Eugene the panda cheering" />
      <span className="eugene-celebrate-msg">{message}</span>
    </div>
  );
}
