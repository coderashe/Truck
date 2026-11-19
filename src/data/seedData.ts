import {
  ExpenseCategory,
  HaulageOrder,
  Invoice,
  OrderSource,
  OrderStatus,
  PaymentStatus,
  TruckFlowState,
} from '../types/truckflow';

function seededRandom(seed: number): () => number {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  return () => {
    s = (s * 16807) % 2147483647;
    return (s - 1) / 2147483646;
  };
}

export function createZimbabweanSeedState(): TruckFlowState {
  const rng = seededRandom(42);
  const now = new Date();

  const company = {
    name: 'ZimHaul Freight & Logistics (Pvt) Ltd',
    address: '42 Lytton Road, Workington, Harare, Zimbabwe',
    phone: '+263 242 754 890',
    email: 'dispatch@zimhaul.co.zw',
    taxNumber: 'BPN 200489120 / TIN 10045219',
    bankDetails:
      'Stanbic Bank Zimbabwe • Workington Branch • Acc: 9140004829103 (USD Nostro)',
    currency: 'USD',
    defaultRatePerKm: 1.75,
    defaultRoundTrip: true,
    invoiceFooter:
      'Thank you for choosing ZimHaul Freight. All accounts due within 14 days.',
    invoiceAccentHex: '#0F172A',
    invoiceCounter: 0,
  };

  const trucks = [
    {
      id: 'trk-1',
      regNumber: 'AFX 4821',
      makeModel: 'Volvo FH16 6x4',
      capacityTonnes: 34,
      fuelType: 'Diesel',
      status: 'Active' as const,
    },
    {
      id: 'trk-2',
      regNumber: 'AFZ 9104',
      makeModel: 'Scania R500 V8',
      capacityTonnes: 32,
      fuelType: 'Diesel',
      status: 'Active' as const,
    },
    {
      id: 'trk-3',
      regNumber: 'AGB 2219',
      makeModel: 'Mercedes-Benz Actros 2645',
      capacityTonnes: 30,
      fuelType: 'Diesel',
      status: 'Active' as const,
    },
    {
      id: 'trk-4',
      regNumber: 'AGC 7730',
      makeModel: 'Freightliner Argosy',
      capacityTonnes: 36,
      fuelType: 'Diesel',
      status: 'Active' as const,
    },
    {
      id: 'trk-5',
      regNumber: 'AGD 1158',
      makeModel: 'MAN TGX 26.540',
      capacityTonnes: 30,
      fuelType: 'Diesel',
      status: 'In Maintenance' as const,
    },
  ];

  const drivers = [
    {
      id: 'drv-1',
      name: 'Tendai Moyo',
      phone: '+263 772 418 902',
      licenceNumber: 'ZW-CE-88421',
      licenceExpiry: '2027-08-15',
      assignedTruckId: 'trk-1',
    },
    {
      id: 'drv-2',
      name: 'Tatenda Chikwanda',
      phone: '+263 773 912 440',
      licenceNumber: 'ZW-CE-71209',
      licenceExpiry: '2027-03-22',
      assignedTruckId: 'trk-2',
    },
    {
      id: 'drv-3',
      name: 'Farai Nyathi',
      phone: '+263 712 604 318',
      licenceNumber: 'ZW-CE-90315',
      licenceExpiry: '2026-12-10',
      assignedTruckId: 'trk-3',
    },
    {
      id: 'drv-4',
      name: 'Blessing Sibanda',
      phone: '+263 782 119 504',
      licenceNumber: 'ZW-CE-66512',
      licenceExpiry: '2027-11-04',
      assignedTruckId: 'trk-4',
    },
  ];

  const customers = [
    {
      id: 'cus-1',
      name: 'Tinashe Gumbo',
      business: 'Lafarge Cement Zimbabwe',
      phone: '+263 772 301 112',
      email: 'orders@lafargezim.co.zw',
      address: 'Manresa Works, Harare',
    },
    {
      id: 'cus-2',
      name: 'Rumbidzai Mupfumi',
      business: 'Delta Beverages Logistics',
      phone: '+263 774 882 190',
      email: 'supply@delta.co.zw',
      address: 'Sable House, Southerton, Harare',
    },
    {
      id: 'cus-3',
      name: 'Kudzai Ndoro',
      business: 'National Foods Ltd',
      phone: '+263 712 445 021',
      email: 'dispatch@natfoods.co.zw',
      address: '10 Stirling Rd, Workington, Harare',
    },
    {
      id: 'cus-4',
      name: 'Chengetai Dube',
      business: 'Tongaat Hulett Hippo Valley',
      phone: '+263 773 519 884',
      email: 'logistics@tongaat.co.zw',
      address: 'Chiredzi Mill, Masvingo',
    },
    {
      id: 'cus-5',
      name: 'Nomsa Ncube',
      business: 'Zimplats Holdings',
      phone: '+263 772 908 773',
      email: 'freight@zimplats.com',
      address: 'Ngezi Complex, Mhondoro',
    },
    {
      id: 'cus-6',
      name: 'Tapiwa Zvobgo',
      business: 'Innscor Africa Distribution',
      phone: '+263 782 330 411',
      email: 'fleet@innscor.co.zw',
      address: 'Msasa Industrial, Harare',
    },
    {
      id: 'cus-7',
      name: 'Simbarashe Banda',
      business: 'Grain Marketing Board',
      phone: '+263 712 889 201',
      email: 'transport@gmb.co.zw',
      address: 'Dura Building, Harare',
    },
    {
      id: 'cus-8',
      name: 'Chiedza Choto',
      business: 'Profeeds Zimbabwe',
      phone: '+263 773 114 559',
      email: 'orders@profeeds.co.zw',
      address: 'Willowvale, Harare',
    },
    {
      id: 'cus-9',
      name: 'Mthokozisi Ndlovu',
      business: 'Treger Products',
      phone: '+263 772 677 812',
      email: 'shipping@treger.co.zw',
      address: 'Belmont, Bulawayo',
    },
    {
      id: 'cus-10',
      name: 'Vimbai Kaseke',
      business: 'Mutare Board & Paper Mills',
      phone: '+263 774 205 619',
      email: 'cargo@mbpm.co.zw',
      address: 'St Helen Drive, Mutare',
    },
    {
      id: 'cus-11',
      name: 'Garikai Sithole',
      business: 'Sable Chemicals',
      phone: '+263 712 310 998',
      email: 'logistics@sablechem.co.zw',
      address: 'Kwekwe Industrial, Midlands',
    },
    {
      id: 'cus-12',
      name: 'Nyasha Makoni',
      business: 'Border Timbers Ltd',
      phone: '+263 783 412 007',
      email: 'dispatch@bordertimbers.co.zw',
      address: 'Nyamhara, Mutare',
    },
  ];

  const routes = [
    {
      name: 'Harare → Bulawayo',
      pickup: { address: 'Workington, Harare', lat: -17.845, lng: 31.022 },
      dropoff: { address: 'Belmont, Bulawayo', lat: -20.165, lng: 28.583 },
      km: 439,
    },
    {
      name: 'Harare → Mutare',
      pickup: { address: 'Msasa, Harare', lat: -17.84, lng: 31.115 },
      dropoff: { address: 'Nyamhara, Mutare', lat: -18.97, lng: 32.67 },
      km: 263,
    },
    {
      name: 'Harare → Beitbridge',
      pickup: { address: 'Southerton, Harare', lat: -17.861, lng: 31.015 },
      dropoff: { address: 'Beitbridge Border Post', lat: -22.216, lng: 29.999 },
      km: 580,
    },
    {
      name: 'Harare → Victoria Falls',
      pickup: { address: 'Harare Depot', lat: -17.829, lng: 31.052 },
      dropoff: { address: 'Victoria Falls Industrial', lat: -17.932, lng: 25.83 },
      km: 878,
    },
    {
      name: 'Harare → Gweru',
      pickup: { address: 'Harare Depot', lat: -17.829, lng: 31.052 },
      dropoff: { address: 'Gweru Heavy Industrial', lat: -19.45, lng: 29.816 },
      km: 275,
    },
    {
      name: 'Harare → Masvingo',
      pickup: { address: 'Willowvale, Harare', lat: -17.882, lng: 30.985 },
      dropoff: { address: 'Masvingo Depot', lat: -20.074, lng: 30.832 },
      km: 292,
    },
    {
      name: 'Bulawayo → Beitbridge',
      pickup: { address: 'Belmont, Bulawayo', lat: -20.165, lng: 28.583 },
      dropoff: { address: 'Beitbridge Border Post', lat: -22.216, lng: 29.999 },
      km: 321,
    },
    {
      name: 'Harare → Chirundu',
      pickup: { address: 'Workington, Harare', lat: -17.845, lng: 31.022 },
      dropoff: { address: 'Chirundu Border Post', lat: -16.034, lng: 28.851 },
      km: 356,
    },
  ];

  const cargos: [string, number][] = [
    ['Bagged Portland Cement', 32],
    ['Bulk Maize Grain', 34],
    ['Packaged Beverages', 26],
    ['Mining Equipment & Spares', 29.5],
    ['Sawn Timber Loads', 28],
    ['Fertilizer & Agro Inputs', 33],
    ['Steel Coils & Hardware', 31],
  ];

  const sources: OrderSource[] = ['WhatsApp', 'Call', 'Email', 'In-person'];
  const orders: HaulageOrder[] = [];
  const invoices: Invoice[] = [];
  let invCounter = 0;

  for (let i = 0; i < 60; i++) {
    const monthOffset = i % 6;
    const day = rng() < 0.48 ? 25 + Math.floor(rng() * 5) : 1 + Math.floor(rng() * 24);
    const targetMonth = new Date(now.getFullYear(), now.getMonth() - monthOffset, 1);
    const maxDay = new Date(targetMonth.getFullYear(), targetMonth.getMonth() + 1, 0).getDate();
    const tripDate = new Date(
      targetMonth.getFullYear(),
      targetMonth.getMonth(),
      Math.min(day, maxDay),
    );
    const tripIso = tripDate.toISOString().slice(0, 10);

    const custIdx = i < 32 ? i % 4 : Math.floor(rng() * customers.length);
    const cust = customers[custIdx];
    const route = routes[i % routes.length];
    const cargo = cargos[Math.floor(rng() * cargos.length)];
    const truckIdx = i % 4;
    const rate = Number((1.65 + Math.floor(rng() * 4) * 0.1).toFixed(2));
    const roundTrip = rng() < 0.85;
    const chargeableKm = roundTrip ? route.km * 2 : route.km;
    const extras = rng() < 0.25 ? 85 : 0;
    const discount = rng() < 0.1 ? 50 : 0;
    const totalAmount = Number((chargeableKm * rate + extras - discount).toFixed(2));

    let status: OrderStatus;
    if (monthOffset === 0 && i < 6) {
      status = i % 2 === 0 ? 'In Transit' : 'Pending';
    } else if (i % 9 === 0) {
      status = 'Invoiced';
    } else {
      status = 'Paid';
    }

    const orderId = `ord-${String(i + 1).padStart(3, '0')}`;
    let invoiceId: string | undefined;

    if (status === 'Invoiced' || status === 'Paid') {
      invCounter++;
      invoiceId = `inv-${String(invCounter).padStart(3, '0')}`;
      const payStatus: PaymentStatus =
        status === 'Paid' ? 'Paid' : i % 2 === 0 ? 'Partially Paid' : 'Unpaid';
      const amountPaid =
        payStatus === 'Paid'
          ? totalAmount
          : payStatus === 'Partially Paid'
            ? Number((totalAmount * 0.5).toFixed(2))
            : 0;
      const due = new Date(tripDate.getTime() + 14 * 86400000);
      const paidAt = new Date(tripDate.getTime() + 5 * 86400000);

      invoices.push({
        id: invoiceId,
        orderId,
        customerId: cust.id,
        invoiceNumber: `INV-${tripDate.getFullYear()}-${String(invCounter).padStart(4, '0')}`,
        issueDate: tripIso,
        dueDate: due.toISOString().slice(0, 10),
        totalAmount,
        amountPaid,
        paymentStatus: payStatus,
        paymentMethod: amountPaid > 0 ? 'Bank Transfer' : undefined,
        paidAt: amountPaid > 0 ? paidAt.toISOString().slice(0, 10) : undefined,
      });
    }

    orders.push({
      id: orderId,
      customerId: cust.id,
      customerName: cust.business,
      source: sources[i % sources.length],
      pickup: route.pickup,
      dropoff: route.dropoff,
      routeName: route.name,
      distanceKm: route.km,
      roundTrip,
      chargeableKm,
      ratePerKm: rate,
      extras,
      discount,
      totalAmount,
      truckId: trucks[truckIdx].id,
      driverId: drivers[truckIdx].id,
      cargoDescription: cargo[0],
      cargoWeight: cargo[1],
      tripDate: tripIso,
      status,
      invoiceId,
    });
  }

  orders.sort((a, b) => b.tripDate.localeCompare(a.tripDate));
  company.invoiceCounter = invCounter;

  const expenseTemplates: [ExpenseCategory, string, number][] = [
    ['Fuel', 'Diesel refill at Zuva Masvingo Rd', 420],
    ['Tolls/Border Fees', 'Beitbridge border & ZINARA tollgates', 145],
    ['Maintenance/Repairs', 'Routine 15,000km service & filters', 310],
    ['Tyres', 'Steer axle tyre replacement', 540],
    ['Driver Wages', 'Monthly driver haulage allowance', 650],
    ['Insurance', 'Comprehensive commercial fleet cover', 380],
    ['Licences/Permits', 'COMESA & cross-border permit renewal', 210],
    ['Office/Admin', 'Dispatch office airtime & internet', 95],
    ['Other', 'Load tarpaulin & lashing straps', 130],
  ];

  const expenses = Array.from({ length: 40 }, (_, i) => {
    const tmpl = expenseTemplates[i % expenseTemplates.length];
    const dt = new Date(now.getTime() - Math.floor(rng() * 175) * 86400000);
    return {
      id: `exp-${String(i + 1).padStart(3, '0')}`,
      category: tmpl[0],
      amount: Number((tmpl[2] * (0.85 + rng() * 0.4)).toFixed(2)),
      date: dt.toISOString().slice(0, 10),
      description: tmpl[1],
      truckId: tmpl[0] === 'Office/Admin' ? undefined : trucks[i % trucks.length].id,
    };
  }).sort((a, b) => b.date.localeCompare(a.date));

  return {
    company,
    trucks,
    drivers,
    customers,
    orders,
    invoices,
    expenses,
  };
}
