import { FormEvent, useState } from 'react';
import { X } from 'lucide-react';
import {
  CompanyProfile,
  Customer,
  Driver,
  HaulageOrder,
  OrderSource,
  Truck,
} from '../types/truckflow';

interface Props {
  company: CompanyProfile;
  customers: Customer[];
  trucks: Truck[];
  drivers: Driver[];
  onClose: () => void;
  onCreate: (order: Omit<HaulageOrder, 'id'>) => void;
}

const ROUTE_PRESETS = [
  {
    name: 'Harare → Bulawayo',
    pickup: 'Workington, Harare',
    pLat: -17.845,
    pLng: 31.022,
    dropoff: 'Belmont, Bulawayo',
    dLat: -20.165,
    dLng: 28.583,
    km: 439,
  },
  {
    name: 'Harare → Mutare',
    pickup: 'Msasa, Harare',
    pLat: -17.84,
    pLng: 31.115,
    dropoff: 'Nyamhara, Mutare',
    dLat: -18.97,
    dLng: 32.67,
    km: 263,
  },
  {
    name: 'Harare → Beitbridge',
    pickup: 'Southerton, Harare',
    pLat: -17.861,
    pLng: 31.015,
    dropoff: 'Beitbridge Border Post',
    dLat: -22.216,
    dLng: 29.999,
    km: 580,
  },
  {
    name: 'Harare → Victoria Falls',
    pickup: 'Harare Depot',
    pLat: -17.829,
    pLng: 31.052,
    dropoff: 'Victoria Falls Industrial',
    dLat: -17.932,
    dLng: 25.83,
    km: 878,
  },
];

export function OrderFormModal({
  company,
  customers,
  trucks,
  drivers,
  onClose,
  onCreate,
}: Props) {
  const [customerId, setCustomerId] = useState(customers[0]?.id ?? '');
  const [source, setSource] = useState<OrderSource>('WhatsApp');
  const [routeName, setRouteName] = useState('Harare → Bulawayo');
  const [pickupAddress, setPickupAddress] = useState('Workington, Harare');
  const [dropoffAddress, setDropoffAddress] = useState('Belmont, Bulawayo');
  const [pickupCoords, setPickupCoords] = useState({ lat: -17.845, lng: 31.022 });
  const [dropoffCoords, setDropoffCoords] = useState({ lat: -20.165, lng: 28.583 });
  const [distanceKm, setDistanceKm] = useState(439);
  const [roundTrip, setRoundTrip] = useState(company.defaultRoundTrip);
  const [ratePerKm, setRatePerKm] = useState(company.defaultRatePerKm);
  const [extras, setExtras] = useState(0);
  const [discount, setDiscount] = useState(0);
  const [truckId, setTruckId] = useState(trucks[0]?.id ?? '');
  const [driverId, setDriverId] = useState(drivers[0]?.id ?? '');
  const [cargoDescription, setCargoDescription] = useState('Bagged Portland Cement');
  const [cargoWeight, setCargoWeight] = useState(32);
  const [tripDate, setTripDate] = useState(new Date().toISOString().slice(0, 10));

  const chargeableKm = roundTrip ? distanceKm * 2 : distanceKm;
  const baseFreight = chargeableKm * ratePerKm;
  const totalAmount = Math.max(0, Number((baseFreight + extras - discount).toFixed(2)));

  const handlePreset = (name: string) => {
    const preset = ROUTE_PRESETS.find((r) => r.name === name);
    if (!preset) return;
    setRouteName(preset.name);
    setPickupAddress(preset.pickup);
    setDropoffAddress(preset.dropoff);
    setPickupCoords({ lat: preset.pLat, lng: preset.pLng });
    setDropoffCoords({ lat: preset.dLat, lng: preset.dLng });
    setDistanceKm(preset.km);
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const cust = customers.find((c) => c.id === customerId);
    onCreate({
      customerId,
      customerName: cust?.business || cust?.name || 'Customer',
      source,
      pickup: { address: pickupAddress, ...pickupCoords },
      dropoff: { address: dropoffAddress, ...dropoffCoords },
      routeName,
      distanceKm,
      roundTrip,
      chargeableKm,
      ratePerKm,
      extras,
      discount,
      totalAmount,
      truckId,
      driverId,
      cargoDescription,
      cargoWeight,
      tripDate,
      status: 'Pending',
    });
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
      <form
        onSubmit={handleSubmit}
        className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl max-w-2xl w-full shadow-2xl overflow-hidden my-auto"
      >
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
          <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
            New Haulage Order
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-sm">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Customer
              </label>
              <select
                value={customerId}
                onChange={(e) => setCustomerId(e.target.value)}
                required
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              >
                {customers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.business} ({c.name})
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Order Source
              </label>
              <select
                value={source}
                onChange={(e) => setSource(e.target.value as OrderSource)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              >
                {(['WhatsApp', 'Call', 'Email', 'In-person'] as OrderSource[]).map(
                  (s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ),
                )}
              </select>
            </div>
          </div>

          <div>
            <div className="text-xs font-medium text-slate-600 dark:text-slate-400 mb-1.5">
              Quick Corridor Presets
            </div>
            <div className="flex flex-wrap gap-1.5">
              {ROUTE_PRESETS.map((p) => (
                <button
                  key={p.name}
                  type="button"
                  onClick={() => handlePreset(p.name)}
                  className={`px-2.5 py-1 text-xs rounded-md border transition-colors cursor-pointer ${
                    routeName === p.name
                      ? 'bg-slate-900 text-white border-slate-900 dark:bg-amber-500 dark:text-slate-950 dark:border-amber-500 font-semibold'
                      : 'border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                  }`}
                >
                  {p.name}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Pickup Address
              </label>
              <input
                type="text"
                required
                value={pickupAddress}
                onChange={(e) => setPickupAddress(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Drop-off Address
              </label>
              <input
                type="text"
                required
                value={dropoffAddress}
                onChange={(e) => setDropoffAddress(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                One-Way km
              </label>
              <input
                type="number"
                min={1}
                required
                value={distanceKm}
                onChange={(e) => setDistanceKm(Number(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 tabular-nums"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Rate / km ({company.currency})
              </label>
              <input
                type="number"
                step="0.05"
                min={0.1}
                required
                value={ratePerKm}
                onChange={(e) => setRatePerKm(Number(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 tabular-nums"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Extras
              </label>
              <input
                type="number"
                min={0}
                value={extras}
                onChange={(e) => setExtras(Number(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 tabular-nums"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Discount
              </label>
              <input
                type="number"
                min={0}
                value={discount}
                onChange={(e) => setDiscount(Number(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 tabular-nums"
              />
            </div>
          </div>

          <label className="flex items-center justify-between p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer">
            <div>
              <div className="font-medium text-slate-900 dark:text-slate-100">
                Round-Trip Billing (2× Return Leg)
              </div>
              <div className="text-xs text-slate-500">
                Chargeable distance: {chargeableKm.toLocaleString()} km
              </div>
            </div>
            <input
              type="checkbox"
              checked={roundTrip}
              onChange={(e) => setRoundTrip(e.target.checked)}
              className="w-4 h-4 accent-amber-500"
            />
          </label>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Truck
              </label>
              <select
                value={truckId}
                onChange={(e) => setTruckId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              >
                {trucks.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.regNumber} ({t.makeModel})
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Driver
              </label>
              <select
                value={driverId}
                onChange={(e) => setDriverId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              >
                {drivers.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Trip Date
              </label>
              <input
                type="date"
                value={tripDate}
                onChange={(e) => setTripDate(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div className="md:col-span-2">
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Cargo Description
              </label>
              <input
                type="text"
                required
                value={cargoDescription}
                onChange={(e) => setCargoDescription(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Weight (Tonnes)
              </label>
              <input
                type="number"
                step="0.5"
                value={cargoWeight}
                onChange={(e) => setCargoWeight(Number(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 tabular-nums"
              />
            </div>
          </div>

          <div className="rounded-xl bg-slate-900 text-white p-4 flex items-center justify-between">
            <div>
              <div className="text-xs font-semibold text-amber-400">
                Live Trip Calculation
              </div>
              <div className="text-xs text-slate-300 mt-0.5 tabular-nums">
                {chargeableKm} km × {company.currency} {ratePerKm.toFixed(2)}/km
                {extras > 0 ? ` + ${extras} extras` : ''}
                {discount > 0 ? ` − ${discount} discount` : ''}
              </div>
            </div>
            <div className="text-2xl font-extrabold text-amber-400 tabular-nums">
              {company.currency} {totalAmount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </div>
          </div>
        </div>

        <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 text-sm font-medium cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="submit"
            className="px-5 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-sm font-semibold cursor-pointer"
          >
            Save Order
          </button>
        </div>
      </form>
    </div>
  );
}
