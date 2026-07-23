import { Logo } from '../../components/Logo';
import { Icon } from '../../components/Icon';
import { AvatarMenu } from './AvatarMenu';
import type { User } from '../../api/types';

interface TopBarProps {
  user: User;
  onPost: () => void;
  onOpenLeaderboard: () => void;
  onOpenSettings: () => void;
  onLogout: () => void;
  onHome: () => void;
}

export function TopBar({ user, onPost, onOpenLeaderboard, onOpenSettings, onLogout, onHome }: TopBarProps) {
  return (
    <header className="topbar">
      <Logo onClick={onHome} />
      <div className="spacer" />
      <button className="btn btn-post" onClick={onPost}>
        <Icon name="plus" size={18} stroke="#fff" strokeWidth={2.6} />
        Post
      </button>
      <button className="topbar-icon-btn" onClick={onOpenLeaderboard} aria-label="Top droppers leaderboard">
        <Icon name="trophy" size={20} strokeWidth={2} />
      </button>
      <AvatarMenu user={user} onOpenSettings={onOpenSettings} onLogout={onLogout} />
    </header>
  );
}
