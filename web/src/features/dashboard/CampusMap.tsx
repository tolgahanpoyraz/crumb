import { useMemo, useState } from 'react';
import type { CampusLocation, Post } from '../../api/types';
import { Icon } from '../../components/Icon';
import { STATUS_META } from '../../lib/freshness';
import { createProjector } from '../../lib/map';
import type { Coords } from '../../lib/geo';

interface CampusMapProps {
  posts: Post[];
  locations: CampusLocation[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  userCoords: Coords | null;
  emptyText: string;
}

// Static decorative "buildings", matching the reference's stylized campus.
const BLOCKS = [
  { top: '11%', left: '5%', width: 220, height: 200, background: '#d9efdf', radius: 34, rotate: -6 },
  { top: '52%', right: '10%', width: 240, height: 210, background: '#ffe1d1', radius: 30, rotate: 5 },
  { bottom: '8%', left: '10%', width: 180, height: 150, background: '#f0e2d3', radius: 26, rotate: -3 },
];

const SIZE_BY_STATUS: Record<string, number> = { fresh: 42, likely: 40, fading: 36, gone: 32 };

export function CampusMap({ posts, locations, selectedId, onSelect, userCoords, emptyText }: CampusMapProps) {
  const [zoom, setZoom] = useState(1);
  const project = useMemo(() => createProjector(locations), [locations]);

  // Cluster posts by campus location so overlapping drops share one pin.
  const clusters = useMemo(() => {
    const byLoc = new Map<string, Post[]>();
    for (const p of posts) {
      const arr = byLoc.get(p.location.id);
      if (arr) arr.push(p);
      else byLoc.set(p.location.id, [p]);
    }
    return [...byLoc.values()].map((group) => {
      // Feed is most-alive-first, so group[0] is the representative.
      const rep = group[0];
      const pt = project(rep.location.latitude, rep.location.longitude);
      const focused = group.some((p) => p._id === selectedId);
      return { rep, count: group.length, pt, focused };
    });
  }, [posts, project, selectedId]);

  const me = userCoords ? project(userCoords.latitude, userCoords.longitude) : { x: 50, y: 50 };

  return (
    <div className="map">
      <div className="map-canvas" style={{ position: 'absolute', inset: 0, transform: `scale(${zoom})`, transformOrigin: 'center', transition: 'transform 0.2s ease' }}>
        <div className="map-grid-1" />
        <div className="map-grid-2" />
        {BLOCKS.map((b, i) => (
          <div
            key={i}
            className="map-block"
            style={{
              top: b.top,
              left: b.left,
              right: b.right,
              bottom: b.bottom,
              width: b.width,
              height: b.height,
              background: b.background,
              borderRadius: b.radius,
              transform: `rotate(${b.rotate}deg)`,
            }}
          />
        ))}

        {/* you're here */}
        <div className="map-me" style={{ left: `${me.x}%`, top: `${me.y}%` }} title="You're here" />

        {clusters.map(({ rep, count, pt, focused }) => {
          const color = focused ? '#F0653F' : STATUS_META[rep.status].dot;
          const size = focused ? 52 : SIZE_BY_STATUS[rep.status] ?? 38;
          const center = size * 0.42;
          return (
            <button
              key={rep.location.id}
              className={`pin ${focused ? 'focused' : ''}`}
              style={{ left: `${pt.x}%`, top: `${pt.y}%`, zIndex: focused ? 20 : 12 }}
              onClick={() => onSelect(rep._id)}
              aria-label={
                count > 1
                  ? `${count} spots at ${rep.location.name}, including ${rep.foodName}`
                  : `${rep.foodName} at ${rep.location.name}`
              }
            >
              <span
                className="drop"
                style={{
                  width: size,
                  height: size,
                  background: color,
                  boxShadow: `0 8px 16px -4px ${color}99`,
                }}
              >
                <span className="center" style={{ width: center, height: center }} />
              </span>
              {count > 1 && <span className="count">{count}</span>}
            </button>
          );
        })}
      </div>

      <div className="map-controls">
        <button onClick={() => setZoom((z) => Math.min(2, +(z + 0.25).toFixed(2)))} aria-label="Zoom in">
          <Icon name="plus" size={17} strokeWidth={2.4} />
        </button>
        <div className="div" />
        <button onClick={() => setZoom((z) => Math.max(1, +(z - 0.25).toFixed(2)))} aria-label="Zoom out">
          <Icon name="minus" size={17} strokeWidth={2.4} />
        </button>
      </div>

      {posts.length === 0 && <div className="map-chip">{emptyText}</div>}
    </div>
  );
}
