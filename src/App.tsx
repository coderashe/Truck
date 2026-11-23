import { FormEvent, useEffect, useMemo, useState } from 'react';
import {
  Code2,
  FileText,
  LayoutDashboard,
  Moon,
  Phone,
  Plus,
  Receipt,
  RotateCcw,
  Search,
  Settings as SettingsIcon,
  Sun,
  TrendingUp,
  Truck as TruckIcon,
  Users,
  Wallet,
} from 'lucide-react';
import { FlutterCodeExplorer } from './components/FlutterCodeExplorer';
import { InvoiceModal } from './components/InvoiceModal';
import { OrderFormModal } from './components/OrderFormModal';
import { ZimbabweHeatmap } from './components/ZimbabweHeatmap';
import { createZimbabweanSeedState } from './data/seedData';
import {
  ExpenseCategory,
  HaulageOrder,
  Invoice,
  OrderStatus,
  TruckFlowState,
  TruckStatus,
} from './types/truckflow';

type SectionId =
  | 'dashboard'
  | 'orders'
  | 'fleet'
  | 'expenses'
  | 'insights'
  | 'customers'
  | 'settings'
  | 'codebase';

const STORAGE_KEY = 'truckflow_ops_state_v1';

const NAV_ITEMS: { id: SectionId; label: string; icon: typeof LayoutDashboard }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'orders', label: 'Orders & Invoices', icon: Receipt },
  { id: 'fleet', label: 'Fleet & Drivers', icon: TruckIcon },
  { id: 'expenses', label: 'Expenses & P&L', icon: Wallet },
  { id: 'insights', label: 'Insights & Heatmap', icon: TrendingUp },
  { id: 'customers', label: 'Customers', icon: Users },
  { id: 'settings', label: 'Settings', icon: SettingsIcon },
  { id: 'codebase', label: 'Flutter Codebase', icon: Code2 },
];

const STATUS_COLOR: Record<OrderStatus, string> = {
  Pending: 'text-amber-600 dark:text-amber-400',
  Confirmed: 'text-blue-600 dark:text-blue-400',
  'In Transit': 'text-sky-600 dark:text-sky-400',
  Delivered: 'text-teal-600 dark:text-teal-400',
  Invoiced: 'text-indigo-600 dark:text-indigo-400',
  Paid: 'text-emerald-600 dark:text-emerald-400',
  Cancelled: 'text-red-600 dark:text-red-400',
};

function fmtMoney(amount: number, currency: string): string {
  return `${currency} ${amount.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

export default function App() {
  const [state, setState] = useState<TruckFlowState>(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw) as TruckFlowState;
    } catch {
      // ignore parse errors
    }
    return createZimbabweanSeedState();
  });

  const [section, setSection] = useState<SectionId>('dashboard');
  const [dark, setDark] = useState(false);
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [activeInvoiceId, setActiveInvoiceId] = useState<string | null>(null);

  // Filters
  const [orderSearch, setOrderSearch] = useState('');
  const [orderStatusFilter, setOrderStatusFilter] = useState<'All' | OrderStatus>('All');
  const [orderTruckFilter, setOrderTruckFilter] = useState<string>('All');
  const [expensePeriod, setExpensePeriod] = useState<'month' | 'lastMonth' | 'year' | 'all'>('all');
  const [customerSearch, setCustomerSearch] = useState('');
  const [fleetTab, setFleetTab] = useState<'trucks' | 'drivers'>('trucks');
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
  }, [dark]);

  const notify = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2600);
  };

  const currency = state.company.currency;

  // Derived Dashboard & Financial Metrics
  const now = new Date();
  const monthPrefix = now.toISOString().slice(0, 7);
  const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const lastMonthPrefix = lastMonthDate.toISOString().slice(0, 7);
  const yearPrefix = String(now.getFullYear());

  const activeTripsCount = state.orders.filter(
    (o) => o.status === 'Confirmed' || o.status === 'In Transit',
  ).length;
  const pendingOrdersCount = state.orders.filter((o) => o.status === 'Pending').length;
  const unpaidInvoices = state.invoices.filter((i) => i.paymentStatus !== 'Paid');
  const unpaidTotal = unpaidInvoices.reduce(
    (s, i) => s + Math.max(0, i.totalAmount - i.amountPaid),
    0,
  );

  const monthRevenue = state.invoices
    .filter((i) => i.issueDate.startsWith(monthPrefix))
    .reduce((s, i) => s + i.amountPaid, 0);
  const monthExpenses = state.expenses
    .filter((e) => e.date.startsWith(monthPrefix))
    .reduce((s, e) => s + e.amount, 0);

  // Actions
  const handleCreateOrder = (newOrder: Omit<HaulageOrder, 'id'>) => {
    const id = `ord-${Date.now()}`;
    setState((prev) => ({
      ...prev,
      orders: [{ ...newOrder, id }, ...prev.orders],
    }));
    setShowOrderModal(false);
    notify('Haulage order recorded');
  };

  const handleUpdateOrderStatus = (orderId: string, status: OrderStatus) => {
    setState((prev) => ({
      ...prev,
      orders: prev.orders.map((o) => (o.id === orderId ? { ...o, status } : o)),
    }));
    notify(`Order updated to ${status}`);
  };

  const handleGenerateOrOpenInvoice = (order: HaulageOrder) => {
    if (order.invoiceId) {
      setActiveInvoiceId(order.invoiceId);
      return;
    }
    const nextCounter = state.company.invoiceCounter + 1;
    const invId = `inv-${Date.now()}`;
    const today = new Date();
    const due = new Date(today.getTime() + 14 * 86400000);
    const inv: Invoice = {
      id: invId,
      orderId: order.id,
      customerId: order.customerId,
      invoiceNumber: `INV-${today.getFullYear()}-${String(nextCounter).padStart(4, '0')}`,
      issueDate: today.toISOString().slice(0, 10),
      dueDate: due.toISOString().slice(0, 10),
      totalAmount: order.totalAmount,
      amountPaid: 0,
      paymentStatus: 'Unpaid',
    };

    setState((prev) => ({
      ...prev,
      company: { ...prev.company, invoiceCounter: nextCounter },
      invoices: [inv, ...prev.invoices],
      orders: prev.orders.map((o) =>
        o.id === order.id ? { ...o, invoiceId: invId, status: 'Invoiced' } : o,
      ),
    }));
    setActiveInvoiceId(invId);
    notify(`Generated ${inv.invoiceNumber}`);
  };

  const handleRecordPayment = (
    invoiceId: string,
    amountPaid: number,
    method: string,
    paidAt: string,
  ) => {
    setState((prev) => {
      const target = prev.invoices.find((i) => i.id === invoiceId);
      if (!target) return prev;
      const payStatus =
        amountPaid >= target.totalAmount
          ? 'Paid'
          : amountPaid > 0
            ? 'Partially Paid'
            : 'Unpaid';
      return {
        ...prev,
        invoices: prev.invoices.map((i) =>
          i.id === invoiceId
            ? {
                ...i,
                amountPaid,
                paymentStatus: payStatus,
                paymentMethod: method,
                paidAt,
              }
            : i,
        ),
        orders:
          payStatus === 'Paid'
            ? prev.orders.map((o) =>
                o.id === target.orderId ? { ...o, status: 'Paid' } : o,
              )
            : prev.orders,
      };
    });
    notify('Invoice payment updated');
  };

  // Expense form state
  const [expCategory, setExpCategory] = useState<ExpenseCategory>('Fuel');
  const [expAmount, setExpAmount] = useState('');
  const [expDesc, setExpDesc] = useState('');
  const [expTruckId, setExpTruckId] = useState('');
  const [expDate, setExpDate] = useState(now.toISOString().slice(0, 10));

  const handleAddExpense = (e: FormEvent) => {
    e.preventDefault();
    const amt = Number(expAmount);
    if (!amt || amt <= 0 || !expDesc.trim()) return;
    setState((prev) => ({
      ...prev,
      expenses: [
        {
          id: `exp-${Date.now()}`,
          category: expCategory,
          amount: amt,
          date: expDate,
          description: expDesc.trim(),
          truckId: expTruckId || undefined,
        },
        ...prev.expenses,
      ],
    }));
    setExpAmount('');
    setExpDesc('');
    notify('Expense recorded');
  };

  // Fleet quick forms
  const [newTruckReg, setNewTruckReg] = useState('');
  const [newTruckModel, setNewTruckModel] = useState('');
  const [newTruckCap, setNewTruckCap] = useState('34');
  const handleAddTruck = (e: FormEvent) => {
    e.preventDefault();
    if (!newTruckReg.trim() || !newTruckModel.trim()) return;
    setState((prev) => ({
      ...prev,
      trucks: [
        ...prev.trucks,
        {
          id: `trk-${Date.now()}`,
          regNumber: newTruckReg.trim().toUpperCase(),
          makeModel: newTruckModel.trim(),
          capacityTonnes: Number(newTruckCap) || 30,
          fuelType: 'Diesel',
          status: 'Active' as TruckStatus,
        },
      ],
    }));
    setNewTruckReg('');
    setNewTruckModel('');
    notify('Truck added to fleet');
  };

  const [newDriverName, setNewDriverName] = useState('');
  const [newDriverPhone, setNewDriverPhone] = useState('');
  const [newDriverLicence, setNewDriverLicence] = useState('');
  const handleAddDriver = (e: FormEvent) => {
    e.preventDefault();
    if (!newDriverName.trim() || !newDriverPhone.trim()) return;
    setState((prev) => ({
      ...prev,
      drivers: [
        ...prev.drivers,
        {
          id: `drv-${Date.now()}`,
          name: newDriverName.trim(),
          phone: newDriverPhone.trim(),
          licenceNumber: newDriverLicence.trim() || 'ZW-CE-NEW',
          licenceExpiry: '2027-12-31',
          assignedTruckId: prev.trucks[0]?.id ?? '',
        },
      ],
    }));
    setNewDriverName('');
    setNewDriverPhone('');
    setNewDriverLicence('');
    notify('Driver added');
  };

  // Customer quick form
  const [newCustName, setNewCustName] = useState('');
  const [newCustBiz, setNewCustBiz] = useState('');
  const [newCustPhone, setNewCustPhone] = useState('');
  const handleAddCustomer = (e: FormEvent) => {
    e.preventDefault();
    if (!newCustName.trim() || !newCustPhone.trim()) return;
    setState((prev) => ({
      ...prev,
      customers: [
        {
          id: `cus-${Date.now()}`,
          name: newCustName.trim(),
          business: newCustBiz.trim() || newCustName.trim(),
          phone: newCustPhone.trim(),
          email: '',
          address: '',
        },
        ...prev.customers,
      ],
    }));
    setNewCustName('');
    setNewCustBiz('');
    setNewCustPhone('');
    notify('Customer added');
  };

  // Filtered Orders
  const filteredOrders = useMemo(() => {
    const q = orderSearch.trim().toLowerCase();
    return state.orders.filter((o) => {
      if (orderStatusFilter !== 'All' && o.status !== orderStatusFilter) return false;
      if (orderTruckFilter !== 'All' && o.truckId !== orderTruckFilter) return false;
      if (q) {
        const hay = `${o.customerName} ${o.routeName} ${o.cargoDescription}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }, [state.orders, orderSearch, orderStatusFilter, orderTruckFilter]);

  // Filtered Financials
  const filteredExpenses = useMemo(() => {
    return state.expenses.filter((e) => {
      if (expensePeriod === 'month') return e.date.startsWith(monthPrefix);
      if (expensePeriod === 'lastMonth') return e.date.startsWith(lastMonthPrefix);
      if (expensePeriod === 'year') return e.date.startsWith(yearPrefix);
      return true;
    });
  }, [state.expenses, expensePeriod, monthPrefix, lastMonthPrefix, yearPrefix]);

  const filteredInvoices = useMemo(() => {
    return state.invoices.filter((i) => {
      if (expensePeriod === 'month') return i.issueDate.startsWith(monthPrefix);
      if (expensePeriod === 'lastMonth') return i.issueDate.startsWith(lastMonthPrefix);
      if (expensePeriod === 'year') return i.issueDate.startsWith(yearPrefix);
      return true;
    });
  }, [state.invoices, expensePeriod, monthPrefix, lastMonthPrefix, yearPrefix]);

  const periodRevenue = filteredInvoices.reduce((s, i) => s + i.amountPaid, 0);
  const periodExpensesTotal = filteredExpenses.reduce((s, e) => s + e.amount, 0);
  const periodProfit = periodRevenue - periodExpensesTotal;

  // Monthly 6-month chart data
  const monthlySeries = useMemo(() => {
    const months: { key: string; label: string; revenue: number; expenses: number }[] = [];
    for (let i = 5; i >= 0; i--) {
      const dt = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = dt.toISOString().slice(0, 7);
      const label = dt.toLocaleDateString('en-US', { month: 'short' });
      const rev = state.invoices
        .filter((inv) => inv.issueDate.startsWith(key))
        .reduce((s, inv) => s + inv.amountPaid, 0);
      const exp = state.expenses
        .filter((ex) => ex.date.startsWith(key))
        .reduce((s, ex) => s + ex.amount, 0);
      months.push({ key, label, revenue: rev, expenses: exp });
    }
    return months;
  }, [state.invoices, state.expenses]);

  // Insights Aggregations
  const insights = useMemo(() => {
    const validOrders = state.orders.filter((o) => o.status !== 'Cancelled');
    const totalKm = validOrders.reduce((s, o) => s + o.chargeableKm, 0);
    const totalExp = state.expenses.reduce((s, e) => s + e.amount, 0);
    const costPerKm = totalKm > 0 ? totalExp / totalKm : 0.75;

    const custAgg = new Map<string, { name: string; count: number; revenue: number }>();
    const routeAgg = new Map<string, { name: string; trips: number; revenue: number; profit: number }>();
    const domCounts = Array.from({ length: 31 }, () => 0);

    for (const o of validOrders) {
      const c = custAgg.get(o.customerId) ?? { name: o.customerName, count: 0, revenue: 0 };
      c.count += 1;
      c.revenue += o.totalAmount;
      custAgg.set(o.customerId, c);

      const r = routeAgg.get(o.routeName) ?? {
        name: o.routeName,
        trips: 0,
        revenue: 0,
        profit: 0,
      };
      r.trips += 1;
      r.revenue += o.totalAmount;
      r.profit += o.totalAmount - o.chargeableKm * costPerKm;
      routeAgg.set(o.routeName, r);

      const day = Number(o.tripDate.slice(8, 10));
      if (day >= 1 && day <= 31) domCounts[day - 1] += 1;
    }

    const topCustomers = Array.from(custAgg.values()).sort((a, b) => b.revenue - a.revenue);
    const topRoutes = Array.from(routeAgg.values()).sort((a, b) => b.profit - a.profit);
    const truckPerf = state.trucks
      .map((t) => {
        const tOrders = validOrders.filter((o) => o.truckId === t.id);
        const rev = tOrders.reduce((s, o) => s + o.totalAmount, 0);
        const km = tOrders.reduce((s, o) => s + o.chargeableKm, 0);
        const exp = state.expenses
          .filter((e) => e.truckId === t.id)
          .reduce((s, e) => s + e.amount, 0);
        return {
          ...t,
          trips: tOrders.length,
          km,
          revenue: rev,
          expenses: exp,
          netProfit: rev - exp,
        };
      })
      .sort((a, b) => b.netProfit - a.netProfit);

    let peakDay = 1;
    let peakCount = 0;
    domCounts.forEach((cnt, idx) => {
      if (cnt > peakCount) {
        peakCount = cnt;
        peakDay = idx + 1;
      }
    });

    return { topCustomers, topRoutes, truckPerf, domCounts, peakDay, peakCount };
  }, [state.orders, state.expenses, state.trucks]);

  const activeInvoice = state.invoices.find((i) => i.id === activeInvoiceId);
  const activeInvoiceOrder = activeInvoice
    ? state.orders.find((o) => o.id === activeInvoice.orderId)
    : undefined;

  const currentNavLabel = NAV_ITEMS.find((n) => n.id === section)?.label ?? 'Dashboard';

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100">
      {/* Sidebar */}
      <aside className="no-print w-full md:w-64 shrink-0 border-b md:border-b-0 md:border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex flex-col justify-between">
        <div>
          <div className="px-5 py-4 border-b border-slate-200 dark:border-slate-800 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-slate-900 dark:bg-amber-500 flex items-center justify-center shrink-0">
              <TruckIcon className="w-5 h-5 text-amber-400 dark:text-slate-950" />
            </div>
            <div className="min-w-0">
              <div className="font-display font-bold text-base tracking-tight truncate">
                TruckFlow
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 truncate">
                {state.company.name}
              </div>
            </div>
          </div>

          <nav className="p-3 flex md:flex-col gap-1 overflow-x-auto">
            {NAV_ITEMS.map((item) => {
              const Icon = item.icon;
              const active = section === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setSection(item.id)}
                  className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                    active
                      ? 'bg-slate-900 text-white dark:bg-amber-500 dark:text-slate-950 font-semibold'
                      : 'text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                  }`}
                >
                  <Icon className="w-4 h-4 shrink-0" />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        <div className="hidden md:flex items-center justify-between px-4 py-3 border-t border-slate-200 dark:border-slate-800 text-xs text-slate-500 dark:text-slate-400">
          <span>Flutter + Firebase</span>
          <button
            onClick={() => setDark((d) => !d)}
            aria-label="Toggle color theme"
            className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
          >
            {dark ? <Sun className="w-3.5 h-3.5" /> : <Moon className="w-3.5 h-3.5" />}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 min-w-0 flex flex-col">
        <header className="no-print h-16 px-6 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center justify-between gap-8">
          <div className="text-sm font-medium text-slate-600 dark:text-slate-300 whitespace-nowrap truncate">
            <span className="text-slate-400 dark:text-slate-500">TruckFlow / </span>
            <span className="text-slate-900 dark:text-slate-100 font-semibold">
              {currentNavLabel}
            </span>
          </div>

          <div className="flex items-center gap-3 shrink-0">
            <button
              onClick={() => setDark((d) => !d)}
              className="md:hidden p-2 rounded-lg border border-slate-200 dark:border-slate-700"
              aria-label="Toggle color theme"
            >
              {dark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
            <button
              onClick={() => setShowOrderModal(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-semibold transition-colors whitespace-nowrap shrink-0 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              New Order
            </button>
          </div>
        </header>

        <main className="flex-1 p-6 max-w-[1200px] w-full mx-auto space-y-6">
          {/* DASHBOARD */}
          {section === 'dashboard' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    Active Trips
                  </div>
                  <div className="text-2xl font-bold tabular-nums mt-1">
                    {activeTripsCount}
                  </div>
                  <div className="text-xs text-slate-500 mt-1">
                    Confirmed & in transit
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    Pending Orders
                  </div>
                  <div className="text-2xl font-bold tabular-nums mt-1 text-amber-600 dark:text-amber-400">
                    {pendingOrdersCount}
                  </div>
                  <div className="text-xs text-slate-500 mt-1">
                    Awaiting dispatch
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    Unpaid Receivables
                  </div>
                  <div className="text-2xl font-bold tabular-nums mt-1 text-red-600 dark:text-red-400">
                    {fmtMoney(unpaidTotal, currency)}
                  </div>
                  <div className="text-xs text-slate-500 mt-1">
                    {unpaidInvoices.length} open invoices
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    This Month Net Profit
                  </div>
                  <div
                    className={`text-2xl font-bold tabular-nums mt-1 ${
                      monthRevenue - monthExpenses >= 0
                        ? 'text-emerald-600 dark:text-emerald-400'
                        : 'text-red-600 dark:text-red-400'
                    }`}
                  >
                    {fmtMoney(monthRevenue - monthExpenses, currency)}
                  </div>
                  <div className="text-xs text-slate-500 mt-1 tabular-nums">
                    Rev {fmtMoney(monthRevenue, currency)} · Exp{' '}
                    {fmtMoney(monthExpenses, currency)}
                  </div>
                </div>
              </div>

              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
                <div className="px-5 py-4 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
                  <h2 className="text-base font-semibold">Recent Haulage Orders</h2>
                  <button
                    onClick={() => setSection('orders')}
                    className="text-xs font-semibold text-amber-600 dark:text-amber-400 hover:underline cursor-pointer"
                  >
                    View all {state.orders.length} orders
                  </button>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-slate-50 dark:bg-slate-950/60 text-xs text-slate-500 dark:text-slate-400">
                      <tr>
                        <th className="text-left py-2.5 px-4 font-medium">Route</th>
                        <th className="text-left py-2.5 px-4 font-medium">Customer</th>
                        <th className="text-left py-2.5 px-4 font-medium">Date</th>
                        <th className="text-right py-2.5 px-4 font-medium">Distance</th>
                        <th className="text-right py-2.5 px-4 font-medium">Total</th>
                        <th className="text-left py-2.5 px-4 font-medium">Status</th>
                        <th className="text-right py-2.5 px-4 font-medium">Invoice</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                      {state.orders.slice(0, 8).map((order) => (
                        <tr
                          key={order.id}
                          className="hover:bg-slate-50 dark:hover:bg-slate-800/40"
                        >
                          <td className="py-2.5 px-4 font-medium">{order.routeName}</td>
                          <td className="py-2.5 px-4 text-slate-600 dark:text-slate-300">
                            {order.customerName}
                          </td>
                          <td className="py-2.5 px-4 tabular-nums text-xs text-slate-500">
                            {order.tripDate}
                          </td>
                          <td className="py-2.5 px-4 text-right tabular-nums text-xs text-slate-500">
                            {order.chargeableKm} km
                          </td>
                          <td className="py-2.5 px-4 text-right font-semibold tabular-nums">
                            {fmtMoney(order.totalAmount, currency)}
                          </td>
                          <td className={`py-2.5 px-4 text-xs font-semibold ${STATUS_COLOR[order.status]}`}>
                            {order.status}
                          </td>
                          <td className="py-2.5 px-4 text-right">
                            <button
                              onClick={() => handleGenerateOrOpenInvoice(order)}
                              className="inline-flex items-center gap-1 text-xs font-semibold text-slate-700 dark:text-amber-400 hover:underline cursor-pointer"
                            >
                              <FileText className="w-3.5 h-3.5" />
                              {order.invoiceId ? 'View' : 'Generate'}
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* ORDERS */}
          {section === 'orders' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="relative flex-1 min-w-[240px]">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={orderSearch}
                    onChange={(e) => setOrderSearch(e.target.value)}
                    placeholder="Search customer, route, or cargo..."
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900"
                  />
                </div>
                <select
                  value={orderTruckFilter}
                  onChange={(e) => setOrderTruckFilter(e.target.value)}
                  className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900"
                >
                  <option value="All">All Trucks</option>
                  {state.trucks.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.regNumber} ({t.makeModel})
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex flex-wrap gap-1 p-1 bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg w-fit">
                {(
                  [
                    'All',
                    'Pending',
                    'Confirmed',
                    'In Transit',
                    'Delivered',
                    'Invoiced',
                    'Paid',
                  ] as const
                ).map((status) => (
                  <button
                    key={status}
                    onClick={() => setOrderStatusFilter(status)}
                    className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors cursor-pointer ${
                      orderStatusFilter === status
                        ? 'bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 shadow-xs'
                        : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
                    }`}
                  >
                    {status}
                  </button>
                ))}
              </div>

              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-slate-50 dark:bg-slate-950/60 text-xs text-slate-500">
                      <tr>
                        <th className="text-left py-2.5 px-4 font-medium">Route & Cargo</th>
                        <th className="text-left py-2.5 px-4 font-medium">Customer</th>
                        <th className="text-left py-2.5 px-4 font-medium">Date</th>
                        <th className="text-right py-2.5 px-4 font-medium">Billing</th>
                        <th className="text-right py-2.5 px-4 font-medium">Total</th>
                        <th className="text-left py-2.5 px-4 font-medium">Status</th>
                        <th className="text-right py-2.5 px-4 font-medium">Invoice</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                      {filteredOrders.map((order) => (
                        <tr key={order.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                          <td className="py-3 px-4">
                            <div className="font-semibold">{order.routeName}</div>
                            <div className="text-xs text-slate-500">
                              {order.cargoDescription} ({order.cargoWeight}t) · {order.source}
                            </div>
                          </td>
                          <td className="py-3 px-4">{order.customerName}</td>
                          <td className="py-3 px-4 tabular-nums text-xs text-slate-500">
                            {order.tripDate}
                          </td>
                          <td className="py-3 px-4 text-right text-xs tabular-nums text-slate-500">
                            {order.chargeableKm} km @ {fmtMoney(order.ratePerKm, currency)}
                            <div>{order.roundTrip ? 'Round-trip' : 'One-way'}</div>
                          </td>
                          <td className="py-3 px-4 text-right font-bold tabular-nums">
                            {fmtMoney(order.totalAmount, currency)}
                          </td>
                          <td className="py-3 px-4">
                            <select
                              value={order.status}
                              onChange={(e) =>
                                handleUpdateOrderStatus(
                                  order.id,
                                  e.target.value as OrderStatus,
                                )
                              }
                              className={`text-xs font-semibold bg-transparent border border-slate-200 dark:border-slate-700 rounded-md px-2 py-1 ${STATUS_COLOR[order.status]}`}
                            >
                              {(
                                [
                                  'Pending',
                                  'Confirmed',
                                  'In Transit',
                                  'Delivered',
                                  'Invoiced',
                                  'Paid',
                                  'Cancelled',
                                ] as OrderStatus[]
                              ).map((s) => (
                                <option key={s} value={s} className="text-slate-900">
                                  {s}
                                </option>
                              ))}
                            </select>
                          </td>
                          <td className="py-3 px-4 text-right">
                            <button
                              onClick={() => handleGenerateOrOpenInvoice(order)}
                              className="px-2.5 py-1 rounded-md border border-slate-200 dark:border-slate-700 text-xs font-semibold hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
                            >
                              {order.invoiceId ? 'Open PDF' : 'Generate'}
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* FLEET */}
          {section === 'fleet' && (
            <div className="space-y-4">
              <div className="flex gap-1 p-1 bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg w-fit">
                <button
                  onClick={() => setFleetTab('trucks')}
                  className={`px-4 py-1.5 text-xs font-semibold rounded-md cursor-pointer ${
                    fleetTab === 'trucks'
                      ? 'bg-white dark:bg-slate-800 shadow-xs'
                      : 'text-slate-500'
                  }`}
                >
                  Trucks ({state.trucks.length})
                </button>
                <button
                  onClick={() => setFleetTab('drivers')}
                  className={`px-4 py-1.5 text-xs font-semibold rounded-md cursor-pointer ${
                    fleetTab === 'drivers'
                      ? 'bg-white dark:bg-slate-800 shadow-xs'
                      : 'text-slate-500'
                  }`}
                >
                  Drivers ({state.drivers.length})
                </button>
              </div>

              {fleetTab === 'trucks' ? (
                <div className="space-y-4">
                  <form
                    onSubmit={handleAddTruck}
                    className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 flex flex-wrap items-end gap-3"
                  >
                    <div>
                      <label className="block text-xs text-slate-500 mb-1">
                        Reg Number
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="AGE 4402"
                        value={newTruckReg}
                        onChange={(e) => setNewTruckReg(e.target.value)}
                        className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                      />
                    </div>
                    <div className="flex-1 min-w-[180px]">
                      <label className="block text-xs text-slate-500 mb-1">
                        Make & Model
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Volvo FH16"
                        value={newTruckModel}
                        onChange={(e) => setNewTruckModel(e.target.value)}
                        className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-slate-500 mb-1">
                        Capacity (t)
                      </label>
                      <input
                        type="number"
                        value={newTruckCap}
                        onChange={(e) => setNewTruckCap(e.target.value)}
                        className="w-24 px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent tabular-nums"
                      />
                    </div>
                    <button
                      type="submit"
                      className="px-4 py-2 rounded-lg bg-slate-900 dark:bg-amber-500 text-white dark:text-slate-950 text-xs font-semibold cursor-pointer"
                    >
                      Add Truck
                    </button>
                  </form>

                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {state.trucks.map((truck) => (
                      <div
                        key={truck.id}
                        className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 space-y-2"
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-base">{truck.regNumber}</span>
                          <span
                            className={`text-xs font-semibold ${
                              truck.status === 'Active'
                                ? 'text-emerald-600'
                                : truck.status === 'In Maintenance'
                                  ? 'text-amber-600'
                                  : 'text-slate-500'
                            }`}
                          >
                            {truck.status}
                          </span>
                        </div>
                        <div className="text-sm text-slate-600 dark:text-slate-300">
                          {truck.makeModel}
                        </div>
                        <div className="text-xs text-slate-500">
                          {truck.capacityTonnes} tonnes · {truck.fuelType}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <form
                    onSubmit={handleAddDriver}
                    className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 flex flex-wrap items-end gap-3"
                  >
                    <div className="flex-1 min-w-[160px]">
                      <label className="block text-xs text-slate-500 mb-1">
                        Driver Name
                      </label>
                      <input
                        type="text"
                        required
                        value={newDriverName}
                        onChange={(e) => setNewDriverName(e.target.value)}
                        className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-slate-500 mb-1">Phone</label>
                      <input
                        type="text"
                        required
                        value={newDriverPhone}
                        onChange={(e) => setNewDriverPhone(e.target.value)}
                        className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-slate-500 mb-1">
                        Licence No.
                      </label>
                      <input
                        type="text"
                        value={newDriverLicence}
                        onChange={(e) => setNewDriverLicence(e.target.value)}
                        className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                      />
                    </div>
                    <button
                      type="submit"
                      className="px-4 py-2 rounded-lg bg-slate-900 dark:bg-amber-500 text-white dark:text-slate-950 text-xs font-semibold cursor-pointer"
                    >
                      Add Driver
                    </button>
                  </form>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {state.drivers.map((driver) => {
                      const truck = state.trucks.find(
                        (t) => t.id === driver.assignedTruckId,
                      );
                      return (
                        <div
                          key={driver.id}
                          className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 flex items-center justify-between"
                        >
                          <div>
                            <div className="font-semibold">{driver.name}</div>
                            <div className="text-xs text-slate-500 mt-0.5">
                              {driver.phone} · Licence {driver.licenceNumber}
                            </div>
                            <div className="text-xs text-slate-500 mt-0.5">
                              Expires {driver.licenceExpiry}
                              {truck ? ` · Assigned ${truck.regNumber}` : ''}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* EXPENSES & P&L */}
          {section === 'expenses' && (
            <div className="space-y-6">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex gap-1 p-1 bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg">
                  {(
                    [
                      ['month', 'This Month'],
                      ['lastMonth', 'Last Month'],
                      ['year', 'This Year'],
                      ['all', 'All Time'],
                    ] as const
                  ).map(([val, label]) => (
                    <button
                      key={val}
                      onClick={() => setExpensePeriod(val)}
                      className={`px-3 py-1.5 text-xs font-medium rounded-md cursor-pointer ${
                        expensePeriod === val
                          ? 'bg-white dark:bg-slate-800 shadow-xs'
                          : 'text-slate-500'
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500">Revenue (Paid)</div>
                  <div className="text-2xl font-bold tabular-nums text-emerald-600 mt-1">
                    {fmtMoney(periodRevenue, currency)}
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500">Outstanding Receivables</div>
                  <div className="text-2xl font-bold tabular-nums text-amber-600 mt-1">
                    {fmtMoney(unpaidTotal, currency)}
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500">Total Expenses</div>
                  <div className="text-2xl font-bold tabular-nums text-red-600 mt-1">
                    {fmtMoney(periodExpensesTotal, currency)}
                  </div>
                </div>
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs text-slate-500">Net Profit</div>
                  <div
                    className={`text-2xl font-bold tabular-nums mt-1 ${
                      periodProfit >= 0 ? 'text-emerald-600' : 'text-red-600'
                    }`}
                  >
                    {fmtMoney(periodProfit, currency)}
                  </div>
                </div>
              </div>

              {/* 6-Month Bar Chart */}
              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-5">
                <h3 className="text-sm font-semibold mb-4">
                  Monthly Income vs Expenses (Last 6 Months)
                </h3>
                <div className="grid grid-cols-6 gap-4 items-end h-44 pt-4">
                  {monthlySeries.map((m) => {
                    const maxVal = Math.max(
                      1,
                      ...monthlySeries.flatMap((x) => [x.revenue, x.expenses]),
                    );
                    const revH = Math.round((m.revenue / maxVal) * 100);
                    const expH = Math.round((m.expenses / maxVal) * 100);
                    return (
                      <div key={m.key} className="flex flex-col items-center gap-2 h-full justify-end">
                        <div className="flex items-end gap-1.5 h-32">
                          <div
                            title={`Revenue: ${fmtMoney(m.revenue, currency)}`}
                            className="w-4 rounded-t bg-emerald-500"
                            style={{ height: `${Math.max(4, revH)}%` }}
                          />
                          <div
                            title={`Expenses: ${fmtMoney(m.expenses, currency)}`}
                            className="w-4 rounded-t bg-red-500"
                            style={{ height: `${Math.max(4, expH)}%` }}
                          />
                        </div>
                        <div className="text-xs text-slate-500">{m.label}</div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Add Expense Form */}
              <form
                onSubmit={handleAddExpense}
                className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 flex flex-wrap items-end gap-3"
              >
                <div>
                  <label className="block text-xs text-slate-500 mb-1">Category</label>
                  <select
                    value={expCategory}
                    onChange={(e) => setExpCategory(e.target.value as ExpenseCategory)}
                    className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
                  >
                    {(
                      [
                        'Fuel',
                        'Maintenance/Repairs',
                        'Tyres',
                        'Driver Wages',
                        'Insurance',
                        'Licences/Permits',
                        'Tolls/Border Fees',
                        'Office/Admin',
                        'Other',
                      ] as ExpenseCategory[]
                    ).map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs text-slate-500 mb-1">
                    Amount ({currency})
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={expAmount}
                    onChange={(e) => setExpAmount(e.target.value)}
                    className="w-32 px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent tabular-nums"
                  />
                </div>
                <div className="flex-1 min-w-[200px]">
                  <label className="block text-xs text-slate-500 mb-1">
                    Description
                  </label>
                  <input
                    type="text"
                    required
                    value={expDesc}
                    onChange={(e) => setExpDesc(e.target.value)}
                    placeholder="e.g. Diesel refill at Zuva"
                    className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block text-xs text-slate-500 mb-1">Truck</label>
                  <select
                    value={expTruckId}
                    onChange={(e) => setExpTruckId(e.target.value)}
                    className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
                  >
                    <option value="">General</option>
                    {state.trucks.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.regNumber}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs text-slate-500 mb-1">Date</label>
                  <input
                    type="date"
                    value={expDate}
                    onChange={(e) => setExpDate(e.target.value)}
                    className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-semibold cursor-pointer"
                >
                  Add Expense
                </button>
              </form>

              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 dark:bg-slate-950/60 text-xs text-slate-500">
                    <tr>
                      <th className="text-left py-2.5 px-4 font-medium">Description</th>
                      <th className="text-left py-2.5 px-4 font-medium">Category</th>
                      <th className="text-left py-2.5 px-4 font-medium">Truck</th>
                      <th className="text-left py-2.5 px-4 font-medium">Date</th>
                      <th className="text-right py-2.5 px-4 font-medium">Amount</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                    {filteredExpenses.slice(0, 20).map((exp) => {
                      const trk = state.trucks.find((t) => t.id === exp.truckId);
                      return (
                        <tr key={exp.id}>
                          <td className="py-2.5 px-4 font-medium">{exp.description}</td>
                          <td className="py-2.5 px-4 text-xs text-slate-500">
                            {exp.category}
                          </td>
                          <td className="py-2.5 px-4 text-xs text-slate-500">
                            {trk?.regNumber ?? 'General'}
                          </td>
                          <td className="py-2.5 px-4 text-xs tabular-nums text-slate-500">
                            {exp.date}
                          </td>
                          <td className="py-2.5 px-4 text-right font-semibold text-red-600 tabular-nums">
                            {fmtMoney(exp.amount, currency)}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* INSIGHTS & HEATMAP */}
          {section === 'insights' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {insights.topRoutes[0] && (
                  <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                    <div className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                      Top Route Profit
                    </div>
                    <div className="text-sm font-semibold mt-1">
                      {insights.topRoutes[0].name}
                    </div>
                    <div className="text-xs text-slate-500 mt-1 tabular-nums">
                      {fmtMoney(insights.topRoutes[0].profit, currency)} est. profit across{' '}
                      {insights.topRoutes[0].trips} trips
                    </div>
                  </div>
                )}
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                  <div className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                    Peak Dispatch Day
                  </div>
                  <div className="text-sm font-semibold mt-1">
                    Day {insights.peakDay} of the month
                  </div>
                  <div className="text-xs text-slate-500 mt-1 tabular-nums">
                    {insights.peakCount} orders · Month-end surge (25th–30th)
                  </div>
                </div>
                {insights.topCustomers[0] && (
                  <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
                    <div className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                      Top Recurring Client
                    </div>
                    <div className="text-sm font-semibold mt-1">
                      {insights.topCustomers[0].name}
                    </div>
                    <div className="text-xs text-slate-500 mt-1 tabular-nums">
                      {insights.topCustomers[0].count} orders ·{' '}
                      {fmtMoney(insights.topCustomers[0].revenue, currency)}
                    </div>
                  </div>
                )}
              </div>

              <ZimbabweHeatmap orders={state.orders} currency={currency} />

              {/* Peak Days of Month Chart */}
              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-5">
                <h3 className="text-sm font-semibold mb-4">
                  Order Volume by Day of Month (1–31)
                </h3>
                <div className="flex items-end gap-1 h-32">
                  {insights.domCounts.map((cnt, idx) => {
                    const max = Math.max(1, ...insights.domCounts);
                    const pct = Math.round((cnt / max) * 100);
                    const day = idx + 1;
                    return (
                      <div
                        key={day}
                        className="flex-1 flex flex-col items-center justify-end h-full gap-1"
                        title={`Day ${day}: ${cnt} orders`}
                      >
                        <div
                          className={`w-full rounded-t ${
                            day >= 25
                              ? 'bg-amber-500'
                              : 'bg-slate-800 dark:bg-slate-500'
                          }`}
                          style={{ height: `${Math.max(4, pct)}%` }}
                        />
                        <span className="text-[10px] text-slate-400 tabular-nums">
                          {day % 5 === 0 || day === 1 ? day : ''}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-5">
                  <h3 className="text-sm font-semibold mb-3">Top Performing Trucks</h3>
                  <div className="divide-y divide-slate-200 dark:divide-slate-800 text-sm">
                    {insights.truckPerf.map((t) => (
                      <div key={t.id} className="py-2.5 flex items-center justify-between">
                        <div>
                          <div className="font-medium">
                            {t.regNumber} · {t.makeModel}
                          </div>
                          <div className="text-xs text-slate-500 tabular-nums">
                            {t.trips} trips · {t.km.toLocaleString()} km · Exp{' '}
                            {fmtMoney(t.expenses, currency)}
                          </div>
                        </div>
                        <div
                          className={`font-bold tabular-nums ${
                            t.netProfit >= 0 ? 'text-emerald-600' : 'text-red-600'
                          }`}
                        >
                          {fmtMoney(t.netProfit, currency)}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-5">
                  <h3 className="text-sm font-semibold mb-3">Recurring Customers</h3>
                  <div className="divide-y divide-slate-200 dark:divide-slate-800 text-sm">
                    {insights.topCustomers.slice(0, 6).map((c) => (
                      <div key={c.name} className="py-2.5 flex items-center justify-between">
                        <div>
                          <div className="font-medium">
                            {c.name}
                            {c.count >= 3 && (
                              <span className="text-xs font-semibold text-amber-600 dark:text-amber-400 ml-2">
                                · Loyal
                              </span>
                            )}
                          </div>
                          <div className="text-xs text-slate-500 tabular-nums">
                            {c.count} orders
                          </div>
                        </div>
                        <div className="font-bold tabular-nums">
                          {fmtMoney(c.revenue, currency)}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* CUSTOMERS */}
          {section === 'customers' && (
            <div className="space-y-4">
              <div className="relative">
                <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={customerSearch}
                  onChange={(e) => setCustomerSearch(e.target.value)}
                  placeholder="Search customers..."
                  className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900"
                />
              </div>

              <form
                onSubmit={handleAddCustomer}
                className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4 flex flex-wrap items-end gap-3"
              >
                <div className="flex-1 min-w-[160px]">
                  <label className="block text-xs text-slate-500 mb-1">
                    Contact Name
                  </label>
                  <input
                    type="text"
                    required
                    value={newCustName}
                    onChange={(e) => setNewCustName(e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <div className="flex-1 min-w-[180px]">
                  <label className="block text-xs text-slate-500 mb-1">
                    Business Name
                  </label>
                  <input
                    type="text"
                    value={newCustBiz}
                    onChange={(e) => setNewCustBiz(e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block text-xs text-slate-500 mb-1">Phone</label>
                  <input
                    type="text"
                    required
                    value={newCustPhone}
                    onChange={(e) => setNewCustPhone(e.target.value)}
                    className="px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg bg-slate-900 dark:bg-amber-500 text-white dark:text-slate-950 text-xs font-semibold cursor-pointer"
                >
                  Add Customer
                </button>
              </form>

              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 dark:bg-slate-950/60 text-xs text-slate-500">
                    <tr>
                      <th className="text-left py-2.5 px-4 font-medium">Business & Contact</th>
                      <th className="text-right py-2.5 px-4 font-medium">Orders</th>
                      <th className="text-right py-2.5 px-4 font-medium">Total Billed</th>
                      <th className="text-right py-2.5 px-4 font-medium">Outstanding</th>
                      <th className="text-right py-2.5 px-4 font-medium">Contact</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                    {state.customers
                      .filter((c) => {
                        const q = customerSearch.trim().toLowerCase();
                        if (!q) return true;
                        return `${c.name} ${c.business} ${c.phone}`
                          .toLowerCase()
                          .includes(q);
                      })
                      .map((c) => {
                        const custOrders = state.orders.filter(
                          (o) => o.customerId === c.id,
                        );
                        const billed = custOrders.reduce(
                          (s, o) => s + o.totalAmount,
                          0,
                        );
                        const due = state.invoices
                          .filter(
                            (i) =>
                              i.customerId === c.id && i.paymentStatus !== 'Paid',
                          )
                          .reduce((s, i) => s + (i.totalAmount - i.amountPaid), 0);
                        const waNum = c.phone.replace(/[^0-9]/g, '');
                        return (
                          <tr key={c.id}>
                            <td className="py-3 px-4">
                              <div className="font-semibold">
                                {c.business}
                                {custOrders.length >= 3 && (
                                  <span className="text-xs text-amber-600 dark:text-amber-400 ml-2">
                                    · Loyal
                                  </span>
                                )}
                              </div>
                              <div className="text-xs text-slate-500">
                                {c.name} · {c.phone}
                              </div>
                            </td>
                            <td className="py-3 px-4 text-right tabular-nums">
                              {custOrders.length}
                            </td>
                            <td className="py-3 px-4 text-right font-semibold tabular-nums">
                              {fmtMoney(billed, currency)}
                            </td>
                            <td
                              className={`py-3 px-4 text-right font-semibold tabular-nums ${
                                due > 0 ? 'text-red-600' : 'text-emerald-600'
                              }`}
                            >
                              {fmtMoney(due, currency)}
                            </td>
                            <td className="py-3 px-4 text-right space-x-2">
                              <a
                                href={`tel:${c.phone}`}
                                className="inline-flex items-center gap-1 text-xs font-medium text-slate-600 dark:text-slate-300 hover:underline"
                              >
                                <Phone className="w-3 h-3" />
                                Call
                              </a>
                              <a
                                href={`https://wa.me/${waNum}`}
                                target="_blank"
                                rel="noreferrer"
                                className="text-xs font-semibold text-emerald-600 hover:underline"
                              >
                                WhatsApp
                              </a>
                            </td>
                          </tr>
                        );
                      })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* SETTINGS */}
          {section === 'settings' && (
            <div className="max-w-2xl space-y-6">
              <div className="border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-6 space-y-4">
                <h2 className="text-base font-semibold">
                  Company Profile & Pricing Defaults
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div className="md:col-span-2">
                    <label className="block text-xs text-slate-500 mb-1">
                      Company Name
                    </label>
                    <input
                      type="text"
                      value={state.company.name}
                      onChange={(e) =>
                        setState((p) => ({
                          ...p,
                          company: { ...p.company, name: e.target.value },
                        }))
                      }
                      className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-slate-500 mb-1">
                      Default Rate / km ({currency})
                    </label>
                    <input
                      type="number"
                      step="0.05"
                      value={state.company.defaultRatePerKm}
                      onChange={(e) =>
                        setState((p) => ({
                          ...p,
                          company: {
                            ...p.company,
                            defaultRatePerKm: Number(e.target.value) || 1.75,
                          },
                        }))
                      }
                      className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent tabular-nums"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-slate-500 mb-1">
                      Currency
                    </label>
                    <select
                      value={state.company.currency}
                      onChange={(e) =>
                        setState((p) => ({
                          ...p,
                          company: { ...p.company, currency: e.target.value },
                        }))
                      }
                      className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
                    >
                      <option value="USD">USD ($)</option>
                      <option value="ZAR">ZAR (R)</option>
                      <option value="ZiG">ZiG</option>
                    </select>
                  </div>
                  <div className="md:col-span-2">
                    <label className="flex items-center justify-between p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer">
                      <span>Default Round-Trip Billing (2×)</span>
                      <input
                        type="checkbox"
                        checked={state.company.defaultRoundTrip}
                        onChange={(e) =>
                          setState((p) => ({
                            ...p,
                            company: {
                              ...p.company,
                              defaultRoundTrip: e.target.checked,
                            },
                          }))
                        }
                        className="w-4 h-4 accent-amber-500"
                      />
                    </label>
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-xs text-slate-500 mb-1">
                      Bank / Payment Details
                    </label>
                    <textarea
                      rows={2}
                      value={state.company.bankDetails}
                      onChange={(e) =>
                        setState((p) => ({
                          ...p,
                          company: { ...p.company, bankDetails: e.target.value },
                        }))
                      }
                      className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-transparent"
                    />
                  </div>
                </div>
                <div className="pt-2 flex items-center justify-between border-t border-slate-200 dark:border-slate-800">
                  <button
                    onClick={() => {
                      setState(createZimbabweanSeedState());
                      notify('Reset to Zimbabwean seed dataset');
                    }}
                    className="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 hover:underline cursor-pointer"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    Reset Sample Seed Data
                  </button>
                  <button
                    onClick={() => notify('Settings saved')}
                    className="px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-semibold cursor-pointer"
                  >
                    Save Settings
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* FLUTTER CODEBASE EXPLORER */}
          {section === 'codebase' && <FlutterCodeExplorer />}
        </main>
      </div>

      {showOrderModal && (
        <OrderFormModal
          company={state.company}
          customers={state.customers}
          trucks={state.trucks}
          drivers={state.drivers}
          onClose={() => setShowOrderModal(false)}
          onCreate={handleCreateOrder}
        />
      )}

      {activeInvoice && activeInvoiceOrder && (
        <InvoiceModal
          company={state.company}
          invoice={activeInvoice}
          order={activeInvoiceOrder}
          customer={state.customers.find(
            (c) => c.id === activeInvoiceOrder.customerId,
          )}
          truck={state.trucks.find((t) => t.id === activeInvoiceOrder.truckId)}
          onClose={() => setActiveInvoiceId(null)}
          onRecordPayment={handleRecordPayment}
        />
      )}

      {toast && (
        <div className="no-print fixed bottom-5 right-5 z-50 px-4 py-2.5 rounded-lg bg-slate-900 dark:bg-amber-500 text-white dark:text-slate-950 text-xs font-semibold shadow-lg">
          {toast}
        </div>
      )}
    </div>
  );
}
