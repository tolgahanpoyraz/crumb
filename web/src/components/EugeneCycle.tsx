import { useState } from 'react';
import munching from '../assets/eugene/munching.png';
import waving from '../assets/eugene/waving.png';
import winking from '../assets/eugene/winking.png';
import cheering from '../assets/eugene/cheering.png';
import starstruck from '../assets/eugene/starstruck.png';
import silly from '../assets/eugene/silly.png';
import crying from '../assets/eugene/crying.png';

interface Mood {
  key: string;
  src: string;
  line: string;
}

// Eugene's seven moods, in cycle order. Each carries one short line in his voice.
const MOODS: Mood[] = [
  { key: 'munching', src: munching, line: 'mmf. quality control.' },
  { key: 'waving', src: waving, line: 'oh hey, you made it.' },
  { key: 'winking', src: winking, line: 'psst — i know where the good stuff is.' },
  { key: 'cheering', src: cheering, line: 'FREE FOOD!' },
  { key: 'starstruck', src: starstruck, line: 'is that... pizza?' },
  { key: 'silly', src: silly, line: 'you saw nothing.' },
  { key: 'crying', src: crying, line: 'someone post something. please.' },
];

interface EugeneCycleProps {
  imgClassName: string;
  start?: string;
}

// A click-to-cycle Eugene: a real button wraps the art, the current mood's line
// lives in a polite live region so cycling is announced to screen readers.
export function EugeneCycle({ imgClassName, start = 'munching' }: EugeneCycleProps) {
  const startIndex = Math.max(0, MOODS.findIndex((m) => m.key === start));
  const [index, setIndex] = useState(startIndex);
  const mood = MOODS[index];

  return (
    <div className="eugene-cycle">
      <span className="eugene-bubble" aria-live="polite">
        {mood.line}
      </span>
      <button
        type="button"
        className="eugene-cycle-btn"
        aria-label="Eugene the panda — click for another mood"
        onClick={() => setIndex((i) => (i + 1) % MOODS.length)}
      >
        <img key={mood.key} className={imgClassName} src={mood.src} alt="" />
      </button>
    </div>
  );
}
