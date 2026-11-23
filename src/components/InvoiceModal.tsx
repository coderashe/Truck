import { useState } from 'react';
import { Printer, Share2, X } from 'lucide-react';
import {
  CompanyProfile,
  Customer,
  HaulageOrder,
  Invoice,
  Truck,
} from '../types/truckflow';

interface Props {
  company: CompanyProfile;
  invoice: Invoice;
  order: HaulageOrder;
  customer?: Customer;
  truck?: Truck;
  onClose: () => void;
  onRecordPayment: (
    invoiceId: string,
    amountPaid: number,
    method: string,
    paidAt: string,
  ) => void;
}

export function InvoiceModal({
  company,
  invoice,
  order,
  customer,
  truck,
  onClose,
  onRecordPayment,
}: Props) {
  const [amountPaid, setAmountPaid] = useState(String(invoice.totalAmount));
  const [method, setMethod] = useState(invoice.paymentMethod ?? 'Bank Transfer');
  const [paidAt, setPaidAt] = useState(new Date().toISOString().slice(0, 10));
  const [showPayForm, setShowPayForm] = useState(false);

  const baseFreight = Number((order.chargeableKm * order.ratePerKm).toFixed(2));
  const balanceDue = Math.max(0, invoice.totalAmount - invoice.amountPaid);

  const whatsappSummary = encodeURIComponent(
    `Hello ${customer?.name ?? order.customerName},\n` +
      `Please find Invoice *${invoice.invoiceNumber}* from *${company.name}*.\n` +
      `Route: ${order.routeName} (${order.chargeableKm} km${order.roundTrip ? ' round-trip' : ''})\n` +
      `Total Due: ${company.currency} ${invoice.totalAmount.toFixed(2)}\n` +
      `Due Date: ${invoice.dueDate}\n` +
      `Bank: ${company.bankDetails}`,
  );
  const cleanPhone = (customer?.phone ?? '').replace(/[^0-9]/g, '');
  const whatsappHref = cleanPhone
    ? `https://wa.me/${cleanPhone}?text=${whatsappSummary}`
    : `https://wa.me/?text=${whatsappSummary}`;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl max-w-3xl w-full shadow-2xl overflow-hidden my-auto">
        <div className="no-print flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
              Invoice {invoice.invoiceNumber}
            </h3>
            <p className="text-xs text-slate-500">
              Status: {invoice.paymentStatus} · Due {invoice.dueDate}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowPayForm((v) => !v)}
              className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-medium text-slate-800 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
            >
              Record Payment
            </button>
            <a
              href={whatsappHref}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold"
            >
              <Share2 className="w-3.5 h-3.5" />
              WhatsApp
            </a>
            <button
              onClick={() => window.print()}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-900 dark:bg-amber-500 text-white dark:text-slate-950 text-xs font-semibold cursor-pointer"
            >
              <Printer className="w-3.5 h-3.5" />
              Print / PDF
            </button>
            <button
              onClick={onClose}
              aria-label="Close invoice"
              className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {showPayForm && (
          <div className="no-print px-6 py-4 bg-slate-50 dark:bg-slate-950/60 border-b border-slate-200 dark:border-slate-800 flex flex-wrap items-end gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Amount Paid ({company.currency})
              </label>
              <input
                type="number"
                step="0.01"
                value={amountPaid}
                onChange={(e) => setAmountPaid(e.target.value)}
                className="px-3 py-1.5 text-sm rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 tabular-nums"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Method
              </label>
              <select
                value={method}
                onChange={(e) => setMethod(e.target.value)}
                className="px-3 py-1.5 text-sm rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900"
              >
                <option value="Bank Transfer">Bank Transfer</option>
                <option value="EcoCash">EcoCash</option>
                <option value="Cash">Cash</option>
                <option value="Card">Card</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                Date Paid
              </label>
              <input
                type="date"
                value={paidAt}
                onChange={(e) => setPaidAt(e.target.value)}
                className="px-3 py-1.5 text-sm rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900"
              />
            </div>
            <button
              onClick={() => {
                onRecordPayment(
                  invoice.id,
                  Number(amountPaid) || 0,
                  method,
                  paidAt,
                );
                setShowPayForm(false);
              }}
              className="px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-semibold cursor-pointer"
            >
              Save Payment
            </button>
          </div>
        )}

        {/* Printable A4 Sheet */}
        <div className="p-8 bg-white text-slate-900 space-y-6 max-h-[75vh] overflow-y-auto">
          <div
            className="rounded-xl p-6 text-white flex flex-wrap justify-between gap-4"
            style={{ backgroundColor: company.invoiceAccentHex }}
          >
            <div>
              <div className="text-lg font-bold">{company.name}</div>
              <div className="text-xs text-slate-300 mt-1">{company.address}</div>
              <div className="text-xs text-slate-300">
                {company.phone} · {company.email}
              </div>
              <div className="text-xs text-amber-400 mt-1">{company.taxNumber}</div>
            </div>
            <div className="text-right">
              <div className="text-2xl font-extrabold text-amber-400">INVOICE</div>
              <div className="text-sm font-semibold mt-1">{invoice.invoiceNumber}</div>
              <div className="text-xs text-slate-300 mt-0.5">
                Status: {invoice.paymentStatus}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-lg bg-slate-50 border border-slate-200">
              <div className="text-xs font-semibold text-slate-500 mb-1">Bill To</div>
              <div className="font-bold text-slate-900">
                {customer?.business || order.customerName}
              </div>
              {customer && (
                <div className="text-xs text-slate-600 space-y-0.5 mt-1">
                  <div>Attn: {customer.name}</div>
                  <div>{customer.phone}</div>
                  <div>{customer.email}</div>
                  <div>{customer.address}</div>
                </div>
              )}
            </div>

            <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 text-xs space-y-1.5">
              <div className="flex justify-between">
                <span className="text-slate-500">Issue Date</span>
                <span className="font-semibold tabular-nums">{invoice.issueDate}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Due Date</span>
                <span className="font-semibold tabular-nums">{invoice.dueDate}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Trip Date</span>
                <span className="font-semibold tabular-nums">{order.tripDate}</span>
              </div>
              {truck && (
                <div className="flex justify-between">
                  <span className="text-slate-500">Vehicle</span>
                  <span className="font-semibold">
                    {truck.regNumber} ({truck.makeModel})
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="p-4 rounded-lg border border-slate-200 text-xs space-y-1">
            <div className="font-semibold text-slate-800">
              Haulage Corridor: {order.routeName}
            </div>
            <div className="text-slate-600">
              Pickup: {order.pickup.address} · Drop-off: {order.dropoff.address}
            </div>
            <div className="text-slate-600">
              Cargo: {order.cargoDescription} ({order.cargoWeight}t) · One-way:{' '}
              {order.distanceKm} km ·{' '}
              {order.roundTrip
                ? 'Round-Trip Billing (2× Return Leg Included)'
                : 'One-Way Billing'}
            </div>
          </div>

          <table className="w-full text-sm border border-slate-200 rounded-lg overflow-hidden">
            <thead
              className="text-white text-xs"
              style={{ backgroundColor: company.invoiceAccentHex }}
            >
              <tr>
                <th className="text-left py-2.5 px-3">Description</th>
                <th className="text-right py-2.5 px-3">Distance / Qty</th>
                <th className="text-right py-2.5 px-3">Rate</th>
                <th className="text-right py-2.5 px-3">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 text-xs">
              <tr>
                <td className="py-3 px-3">
                  <div className="font-medium text-slate-900">
                    Haulage Service ({order.routeName})
                  </div>
                  <div className="text-slate-500">
                    {order.roundTrip
                      ? `${order.distanceKm} km × 2 legs (round-trip)`
                      : `${order.distanceKm} km one-way`}
                  </div>
                </td>
                <td className="py-3 px-3 text-right tabular-nums">
                  {order.chargeableKm} km
                </td>
                <td className="py-3 px-3 text-right tabular-nums">
                  {company.currency} {order.ratePerKm.toFixed(2)}/km
                </td>
                <td className="py-3 px-3 text-right font-semibold tabular-nums">
                  {company.currency} {baseFreight.toFixed(2)}
                </td>
              </tr>
              {order.extras > 0 && (
                <tr>
                  <td className="py-2.5 px-3">Extra Charges (Waiting / Border)</td>
                  <td className="py-2.5 px-3 text-right">1</td>
                  <td className="py-2.5 px-3 text-right tabular-nums">
                    {company.currency} {order.extras.toFixed(2)}
                  </td>
                  <td className="py-2.5 px-3 text-right font-semibold tabular-nums">
                    {company.currency} {order.extras.toFixed(2)}
                  </td>
                </tr>
              )}
              {order.discount > 0 && (
                <tr>
                  <td className="py-2.5 px-3">Agreed Discount</td>
                  <td className="py-2.5 px-3 text-right">1</td>
                  <td className="py-2.5 px-3 text-right tabular-nums">
                    -{company.currency} {order.discount.toFixed(2)}
                  </td>
                  <td className="py-2.5 px-3 text-right font-semibold text-emerald-700 tabular-nums">
                    -{company.currency} {order.discount.toFixed(2)}
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          <div className="flex justify-end">
            <div className="w-64 p-4 rounded-lg bg-slate-50 border border-slate-200 text-xs space-y-1.5">
              <div className="flex justify-between font-bold text-sm text-slate-900">
                <span>Total</span>
                <span className="tabular-nums">
                  {company.currency} {invoice.totalAmount.toFixed(2)}
                </span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Paid</span>
                <span className="tabular-nums">
                  {company.currency} {invoice.amountPaid.toFixed(2)}
                </span>
              </div>
              <div className="flex justify-between font-semibold pt-1.5 border-t border-slate-200">
                <span>Balance Due</span>
                <span className="tabular-nums">
                  {company.currency} {balanceDue.toFixed(2)}
                </span>
              </div>
            </div>
          </div>

          <div className="p-4 rounded-lg border border-slate-200 text-xs">
            <div className="font-semibold text-slate-800 mb-1">
              Payment Instructions
            </div>
            <div className="text-slate-600">{company.bankDetails}</div>
          </div>

          <div className="text-center text-xs text-slate-500 pt-2">
            {company.invoiceFooter}
          </div>
        </div>
      </div>
    </div>
  );
}
