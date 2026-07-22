import { useEffect, useMemo, useRef } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import type { CampusLocation, Post } from '../../api/types';
import { Icon } from '../../components/Icon';
import { STATUS_META } from '../../lib/freshness';
import type { Coords } from '../../lib/geo';

interface MapboxMapProps {
  posts: Post[];
  locations: CampusLocation[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  userCoords: Coords | null;
  emptyText: string;
  token: string;
}

const SIZE_BY_STATUS: Record<string, number> = { fresh: 42, likely: 40, fading: 36, gone: 32 };
const UCF_CENTER: [number, number] = [-81.2001, 28.6019];

// Repaint the stock light basemap into Crumb's warm cream palette so the real
// map reads as the same design system as the stylized canvas fallback.
function recolor(map: mapboxgl.Map) {
  const style = map.getStyle();
  if (!style?.layers) {
    return;
  }
  for (const layer of style.layers) {
    const id = layer.id;
    try {
      if (layer.type === 'symbol') {
        // Symbols first: road-label etc. must not fall into the road-line branch.
        if (/poi|transit|airport|natural-point|water-point/.test(id)) {
          map.setLayoutProperty(id, 'visibility', 'none');
        } else if (id.includes('label')) {
          map.setPaintProperty(id, 'text-color', '#96604f');
          map.setPaintProperty(id, 'text-halo-color', '#fff6ef');
          map.setPaintProperty(id, 'text-halo-width', 1.4);
        }
      } else if (layer.type === 'background') {
        map.setPaintProperty(id, 'background-color', '#f3e2d2');
      } else if (id.startsWith('land') || id === 'landcover' || id.startsWith('landuse')) {
        if (/park|grass|wood|scrub|golf|pitch|cemetery|agriculture/.test(id)) {
          map.setPaintProperty(id, 'fill-color', '#d5e5c6');
        } else {
          map.setPaintProperty(id, 'fill-color', '#f8ebdd');
        }
      } else if (/park|grass|wood|vegetation|green/.test(id) && layer.type === 'fill') {
        map.setPaintProperty(id, 'fill-color', '#d5e5c6');
      } else if (id.startsWith('water')) {
        if (layer.type === 'fill') {
          map.setPaintProperty(id, 'fill-color', '#bcd6da');
        } else if (layer.type === 'line') {
          map.setPaintProperty(id, 'line-color', '#bcd6da');
        }
      } else if (id.startsWith('building')) {
        if (layer.type === 'fill') {
          map.setPaintProperty(id, 'fill-color', '#efdccb');
          map.setPaintProperty(id, 'fill-outline-color', '#e3cdb9');
        }
      } else if (id.includes('road') || id.includes('bridge') || id.includes('tunnel') || id.includes('street')) {
        if (layer.type === 'line') {
          const isCasing = id.includes('case');
          map.setPaintProperty(id, 'line-color', isCasing ? '#e5d0bf' : '#ffffff');
        }
      }
    } catch {
      // Layer schema varies across style versions; skip anything that doesn't take the property.
    }
  }
}

function buildMarkerEl(color: string, size: number, count: number, focused: boolean): HTMLElement {
  const root = document.createElement('div');
  root.className = `mbx-pin${focused ? ' focused' : ''}`;

  const drop = document.createElement('span');
  drop.className = 'drop';
  drop.style.width = `${size}px`;
  drop.style.height = `${size}px`;
  drop.style.background = color;
  drop.style.boxShadow = `0 8px 16px -4px ${color}99`;

  const center = document.createElement('span');
  center.className = 'center';
  const c = size * 0.42;
  center.style.width = `${c}px`;
  center.style.height = `${c}px`;
  drop.appendChild(center);
  root.appendChild(drop);

  if (count > 1) {
    const badge = document.createElement('span');
    badge.className = 'count';
    badge.textContent = String(count);
    root.appendChild(badge);
  }
  return root;
}

export function MapboxMap({ posts, locations, selectedId, onSelect, userCoords, emptyText, token }: MapboxMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const markers = useRef<Map<string, mapboxgl.Marker>>(new Map()).current;
  const userMarkerRef = useRef<mapboxgl.Marker | null>(null);
  const fittedRef = useRef(false);

  // One pin per location that has posts; group[0] is the representative (feed is
  // most-alive-first). Keyed by location id so overlapping drops share a pin.
  const clusters = useMemo(() => {
    const byLoc = new Map<string, Post[]>();
    for (const p of posts) {
      const arr = byLoc.get(p.location.id);
      if (arr) {
        arr.push(p);
      } else {
        byLoc.set(p.location.id, [p]);
      }
    }
    return [...byLoc.entries()].map(([id, group]) => {
      const rep = group[0];
      const focused = group.some((p) => p._id === selectedId);
      return { id, rep, count: group.length, focused };
    });
  }, [posts, selectedId]);

  // Init the map once.
  useEffect(() => {
    if (!containerRef.current) {
      return;
    }
    mapboxgl.accessToken = token;
    const map = new mapboxgl.Map({
      container: containerRef.current,
      style: 'mapbox://styles/mapbox/light-v11',
      center: UCF_CENTER,
      zoom: 14.4,
      minZoom: 13,
      maxZoom: 18,
      attributionControl: false,
    });
    map.addControl(new mapboxgl.AttributionControl({ compact: true }), 'bottom-right');
    map.on('style.load', () => recolor(map));
    mapRef.current = map;

    const ro = new ResizeObserver(() => map.resize());
    ro.observe(containerRef.current);

    return () => {
      ro.disconnect();
      map.remove();
      mapRef.current = null;
      markers.clear();
      fittedRef.current = false;
    };
  }, [token, markers]);

  // Fit to the full campus footprint once locations arrive.
  useEffect(() => {
    const map = mapRef.current;
    if (!map || fittedRef.current || locations.length === 0) {
      return;
    }
    const bounds = new mapboxgl.LngLatBounds();
    for (const l of locations) {
      bounds.extend([l.longitude, l.latitude]);
    }
    map.fitBounds(bounds, { padding: 80, maxZoom: 16.5, duration: 0 });
    fittedRef.current = true;
  }, [locations]);

  // Rebuild markers from the current clusters. Cheap at this scale (a handful of
  // pins) and keeps focus/count/color state trivially in sync.
  useEffect(() => {
    const map = mapRef.current;
    if (!map) {
      return;
    }
    for (const marker of markers.values()) {
      marker.remove();
    }
    markers.clear();

    for (const { id, rep, count, focused } of clusters) {
      const color = focused ? '#F0653F' : STATUS_META[rep.status].dot;
      const size = focused ? 52 : SIZE_BY_STATUS[rep.status] ?? 38;
      const el = buildMarkerEl(color, size, count, focused);
      el.setAttribute('role', 'button');
      el.setAttribute(
        'aria-label',
        count > 1
          ? `${count} spots at ${rep.location.name}, including ${rep.foodName}`
          : `${rep.foodName} at ${rep.location.name}`,
      );
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        onSelect(rep._id);
      });
      const marker = new mapboxgl.Marker({ element: el, anchor: 'bottom' })
        .setLngLat([rep.location.longitude, rep.location.latitude])
        .addTo(map);
      markers.set(id, marker);
    }
  }, [clusters, onSelect, markers]);

  // "You're here" dot.
  useEffect(() => {
    const map = mapRef.current;
    if (!map) {
      return;
    }
    if (!userCoords) {
      userMarkerRef.current?.remove();
      userMarkerRef.current = null;
      return;
    }
    const el = userMarkerRef.current?.getElement() ?? document.createElement('div');
    el.className = 'mbx-me';
    el.title = "You're here";
    const marker = userMarkerRef.current ?? new mapboxgl.Marker({ element: el });
    marker.setLngLat([userCoords.longitude, userCoords.latitude]);
    if (!userMarkerRef.current) {
      userMarkerRef.current = marker.addTo(map);
    }
  }, [userCoords]);

  // Ease to the selected post's location.
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !selectedId) {
      return;
    }
    const sel = posts.find((p) => p._id === selectedId);
    if (sel) {
      map.easeTo({ center: [sel.location.longitude, sel.location.latitude], duration: 600 });
    }
  }, [selectedId, posts]);

  return (
    <div className="map">
      <div ref={containerRef} className="map-gl" />

      <div className="map-controls">
        <button onClick={() => mapRef.current?.zoomIn()} aria-label="Zoom in">
          <Icon name="plus" size={17} strokeWidth={2.4} />
        </button>
        <div className="div" />
        <button onClick={() => mapRef.current?.zoomOut()} aria-label="Zoom out">
          <Icon name="minus" size={17} strokeWidth={2.4} />
        </button>
      </div>

      {posts.length === 0 && <div className="map-chip">{emptyText}</div>}
    </div>
  );
}
