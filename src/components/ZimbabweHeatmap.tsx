import { useMemo, useState } from 'react';
import { HaulageOrder } from '../types/truckflow';

interface Props {
  orders: HaulageOrder[];
  currency: string;
}

type LayerMode = 'Both' | 'Pickups' | 'Drop-offs';

// Project lat (-15.5 to -22.6) and lng (25.0 to 33.2) onto 600x440 SVG canvas
function project(lat: number, lng: number): { x: number; y: number } {
  const minLng = 25.0;
  const maxLng = 33.4;
  const maxLat = -15.4;
  const minLat = -22.6;
  const x = ((lng - minLng) / (maxLng - minLng)) * 540 + 30;
  const y = ((maxLat - lat) / (maxLat - minLat)) * 380 + 30;
  return { x, y };
}

export function ZimbabweHeatmap({ orders, currency }: Props) {
  const [layer, setLayer] = useState<LayerMode>('Both');
  const [selectedRoute, setSelectedRoute] = useState<string | null>(null);

  const routes = useMemo(() => {
    const map = new Map<
      string,
      {
        name: string;
        trips: number;
        revenue: number;
        p1: { x: number; y: number };
        p2: { x: number; y: number };
      }
    >();
    for (const o of orders) {
      if (o.status === 'Cancelled') continue;
      const existing = map.get(o.routeName);
      if (existing) {
        existing.trips += 1;
        existing.revenue += o.totalAmount;
      } else {
        map.set(o.routeName, {
          name: o.routeName,
          trips: 1,
          revenue: o.totalAmount,
          p1: project(o.pickup.lat, o.pickup.lng),
          p2: project(o.dropoff.lat, o.dropoff.lng),
        });
      }
    }
    return Array.from(map.values()).sort((a, b) => b.revenue - a.revenue);
  }, [orders]);

  const hubs = useMemo(() => {
    const map = new Map<
      string,
      { label: string; x: number; y: number; weight: number }
    >();
    for (const o of orders) {
      if (o.status === 'Cancelled') continue;
      if (layer === 'Pickups' || layer === 'Both') {
        const key = `${o.pickup.lat.toFixed(2)},${o.pickup.lng.toFixed(2)}`;
        const p = project(o.pickup.lat, o.pickup.lng);
        const cur = map.get(key);
        if (cur) cur.weight += 1;
        else
          map.set(key, {
            label: o.pickup.address.split(',').pop()?.trim() || o.pickup.address,
            x: p.x,
            y: p.y,
            weight: 1,
          });
      }
      if (layer === 'Drop-offs' || layer === 'Both') {
        const key = `${o.dropoff.lat.toFixed(2)},${o.dropoff.lng.toFixed(2)}`;
        const p = project(o.dropoff.lat, o.dropoff.lng);
        const cur = map.get(key);
        if (cur) cur.weight += 1;
        else
          map.set(key, {
            label: o.dropoff.address.split(',').pop()?.trim() || o.dropoff.address,
            x: p.x,
            y: p.y,
            weight: 1,
          });
      }
    }
    return Array.from(map.values());
  }, [orders, layer]);

  const activeRoute = routes.find((r) => r.name === selectedRoute) ?? routes[0];
  const maxWeight = Math.max(1, ...hubs.map((h) => h.weight));

  return (
    <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-5 space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">
            Route Corridor & Hotspot Heatmap
          </h3>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Tap any corridor line to inspect trip count and revenue
          </p>
        </div>
        <div className="flex items-center gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
          {(['Both', 'Pickups', 'Drop-offs'] as LayerMode[]).map((mode) => (
            <button
              key={mode}
              onClick={() => setLayer(mode)}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                layer === mode
                  ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 shadow-sm'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200'
              }`}
            >
              {mode}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 items-stretch">
        <div className="lg:col-span-8 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-950 overflow-hidden relative">
          <svg
            viewBox="0 0 600 440"
            className="w-full h-[320px] block"
            role="img"
            aria-label="Zimbabwe haulage route heatmap"
          >
            <defs>
              <radialGradient id="heatGlow">
                <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.85" />
                <stop offset="45%" stopColor="#EA580C" stopOpacity="0.35" />
                <stop offset="100%" stopColor="#EA580C" stopOpacity="0" />
              </radialGradient>
            </defs>

            {/* Subtle coordinate grid */}
            {[80, 160, 240, 320, 400].map((y) => (
              <line
                key={`h-${y}`}
                x1={0}
                y1={y}
                x2={600}
                y2={y}
                stroke="#1E293B"
                strokeWidth="1"
              />
            ))}
            {[100, 200, 300, 400, 500].map((x) => (
              <line
                key={`v-${x}`}
                x1={x}
                y1={0}
                x2={x}
                y2={440}
                stroke="#1E293B"
                strokeWidth="1"
              />
            ))}

            {/* Approximate Zimbabwe national border polygon */}
            <polygon
              points="75,155 170,130 280,55 430,75 520,175 495,295 360,395 250,375 180,295 95,235"
              fill="#0F172A"
              stroke="#334155"
              strokeWidth="1.5"
            />

            {/* Heat blobs */}
            {hubs.map((hub, idx) => {
              const radius = 22 + (hub.weight / maxWeight) * 52;
              return (
                <circle
                  key={`heat-${idx}`}
                  cx={hub.x}
                  cy={hub.y}
                  r={radius}
                  fill="url(#heatGlow)"
                />
              );
            })}

            {/* Tappable route lines */}
            {routes.map((route) => {
              const isSelected = activeRoute?.name === route.name;
              return (
                <line
                  key={route.name}
                  x1={route.p1.x}
                  y1={route.p1.y}
                  x2={route.p2.x}
                  y2={route.p2.y}
                  stroke={isSelected ? '#F59E0B' : '#64748B'}
                  strokeWidth={isSelected ? 4 : 2}
                  strokeOpacity={isSelected ? 0.95 : 0.65}
                  className="cursor-pointer transition-all"
                  onClick={() => setSelectedRoute(route.name)}
                />
              );
            })}

            {/* Hub markers */}
            {hubs.map((hub, idx) => (
              <g key={`pin-${idx}`}>
                <circle
                  cx={hub.x}
                  cy={hub.y}
                  r={4.5}
                  fill="#F8FAFC"
                  stroke="#0F172A"
                  strokeWidth="1.5"
                />
                <text
                  x={hub.x + 7}
                  y={hub.y + 4}
                  fill="#CBD5E1"
                  fontSize="10"
                  fontFamily="Public Sans, sans-serif"
                >
                  {hub.label}
                </text>
              </g>
            ))}
          </svg>
        </div>

        <div className="lg:col-span-4 border border-slate-200 dark:border-slate-800 rounded-xl p-4 flex flex-col justify-between bg-slate-50 dark:bg-slate-950/50">
          {activeRoute ? (
            <div className="space-y-3">
              <div className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                Selected Corridor
              </div>
              <div className="text-base font-bold text-slate-900 dark:text-slate-100">
                {activeRoute.name}
              </div>
              <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200 dark:border-slate-800">
                <div>
                  <div className="text-xs text-slate-500">Trips</div>
                  <div className="text-lg font-bold tabular-nums text-slate-900 dark:text-slate-100">
                    {activeRoute.trips}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-slate-500">Revenue</div>
                  <div className="text-lg font-bold tabular-nums text-emerald-600 dark:text-emerald-400">
                    {currency} {activeRoute.revenue.toLocaleString()}
                  </div>
                </div>
              </div>
              <div className="pt-2 border-t border-slate-200 dark:border-slate-800 space-y-1.5">
                <div className="text-xs font-medium text-slate-500">All Corridors</div>
                <div className="max-h-36 overflow-y-auto space-y-1">
                  {routes.map((r) => (
                    <button
                      key={r.name}
                      onClick={() => setSelectedRoute(r.name)}
                      className={`w-full flex items-center justify-between text-xs px-2 py-1 rounded-md text-left cursor-pointer ${
                        activeRoute.name === r.name
                          ? 'bg-slate-900 text-white dark:bg-amber-500 dark:text-slate-950 font-medium'
                          : 'text-slate-700 dark:text-slate-300 hover:bg-slate-200/60 dark:hover:bg-slate-800'
                      }`}
                    >
                      <span className="truncate">{r.name}</span>
                      <span className="tabular-nums shrink-0">{r.trips} trips</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-sm text-slate-500">No route data available.</div>
          )}
        </div>
      </div>
    </div>
  );
}
