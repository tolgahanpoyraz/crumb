import { useRef, useState } from 'react';
import { Avatar } from '../../components/Avatar';
import { Icon } from '../../components/Icon';
import { useClickOutside } from '../../hooks/useClickOutside';
import { initials } from '../../lib/images';
import type { User } from '../../api/types';

interface AvatarMenuProps {
  user: User;
  onOpenSettings: () => void;
  onLogout: () => void;
}

export function AvatarMenu({ user, onOpenSettings, onLogout }: AvatarMenuProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useClickOutside(ref, () => setOpen(false), open);

  return (
    <div className="avatar-menu-anchor" ref={ref}>
      <button
        className="avatar-trigger"
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={`${initials(user.displayName)} — account menu`}
      >
        <Avatar name={user.displayName} avatarKey={user.avatarKey} size={38} ring />
      </button>

      {open && (
        <div className="avatar-menu" role="menu">
          <div className="head">
            <Avatar name={user.displayName} avatarKey={user.avatarKey} size={34} ring />
            <div style={{ minWidth: 0 }}>
              <div className="name">{user.displayName}</div>
              <div className="email">{user.email}</div>
            </div>
          </div>
          <div className="menu-divider" />
          <button
            className="menu-item"
            role="menuitem"
            onClick={() => {
              setOpen(false);
              onOpenSettings();
            }}
          >
            <Icon name="gear" size={17} strokeWidth={2} />
            Settings
          </button>
          <div className="menu-divider" />
          <button
            className="menu-item danger"
            role="menuitem"
            onClick={() => {
              setOpen(false);
              onLogout();
            }}
          >
            <Icon name="logout" size={17} strokeWidth={2} />
            Log out
          </button>
        </div>
      )}
    </div>
  );
}
