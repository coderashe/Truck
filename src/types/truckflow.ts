export type OrderSource = 'WhatsApp' | 'Call' | 'Email' | 'In-person';

export type OrderStatus =
  | 'Pending'
  | 'Confirmed'
  | 'In Transit'
  | 'Delivered'
  | 'Invoiced'
  | 'Paid'
  | 'Cancelled';

export type PaymentStatus = 'Unpaid' | 'Partially Paid' | 'Paid';

export type TruckStatus = 'Active' | 'In Maintenance' | 'Inactive';

export type ExpenseCategory =
  | 'Fuel'
  | 'Maintenance/Repairs'
  | 'Tyres'
  | 'Driver Wages'
  | 'Insurance'
  | 'Licences/Permits'
  | 'Tolls/Border Fees'
  | 'Office/Admin'
  | 'Other';

export interface CompanyProfile {
  name: string;
  address: string;
  phone: string;
  email: string;
  taxNumber: string;
  bankDetails: string;
  currency: string;
  defaultRatePerKm: number;
  defaultRoundTrip: boolean;
  invoiceFooter: string;
  invoiceAccentHex: string;
  invoiceCounter: number;
}

export interface Truck {
  id: string;
  regNumber: string;
  makeModel: string;
  capacityTonnes: number;
  fuelType: string;
  status: TruckStatus;
}

export interface Driver {
  id: string;
  name: string;
  phone: string;
  licenceNumber: string;
  licenceExpiry: string;
  assignedTruckId: string;
}

export interface Customer {
  id: string;
  name: string;
  business: string;
  phone: string;
  email: string;
  address: string;
}

export interface GeoPoint {
  address: string;
  lat: number;
  lng: number;
}

export interface HaulageOrder {
  id: string;
  customerId: string;
  customerName: string;
  source: OrderSource;
  pickup: GeoPoint;
  dropoff: GeoPoint;
  routeName: string;
  distanceKm: number;
  roundTrip: boolean;
  chargeableKm: number;
  ratePerKm: number;
  extras: number;
  discount: number;
  totalAmount: number;
  truckId: string;
  driverId: string;
  cargoDescription: string;
  cargoWeight: number;
  tripDate: string;
  status: OrderStatus;
  invoiceId?: string;
}

export interface Invoice {
  id: string;
  orderId: string;
  customerId: string;
  invoiceNumber: string;
  issueDate: string;
  dueDate: string;
  totalAmount: number;
  amountPaid: number;
  paymentStatus: PaymentStatus;
  paymentMethod?: string;
  paidAt?: string;
}

export interface Expense {
  id: string;
  category: ExpenseCategory;
  amount: number;
  date: string;
  description: string;
  truckId?: string;
}

export interface TruckFlowState {
  company: CompanyProfile;
  trucks: Truck[];
  drivers: Driver[];
  customers: Customer[];
  orders: HaulageOrder[];
  invoices: Invoice[];
  expenses: Expense[];
}
