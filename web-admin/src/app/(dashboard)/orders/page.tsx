'use client';

import { useCallback, useEffect, useState } from 'react';
import { apiFetch } from '@/lib/api';

const STATUSES = [
  'received_china',
  'in_transit',
  'sorting',
  'ready_pickup',
  'with_courier',
  'completed',
] as const;

type OrderRow = {
  id: string;
  trackingCode: string;
  status: string;
  isPaid: boolean;
  weightGrams: number | null;
  client: {
    id: string;
    name: string;
    phone: string;
    clientCode: string | null;
  } | null;
  guestName: string | null;
  guestPhone: string | null;
};

export default function OrdersPage() {
  const [items, setItems] = useState<OrderRow[]>([]);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [trackingCode, setTrackingCode] = useState('');
  const [clientCode, setClientCode] = useState('');
  const [withoutClient, setWithoutClient] = useState(false);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState('');
  const [updating, setUpdating] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const q = new URLSearchParams();
      q.set('take', '100');
      if (status) q.set('status', status);
      if (trackingCode.trim()) q.set('trackingCode', trackingCode.trim());
      if (clientCode.trim()) q.set('clientCode', clientCode.trim());
      if (withoutClient) q.set('withoutClient', '1');
      const res = await apiFetch<{ items: OrderRow[]; total: number }>(
        `/admin/orders?${q.toString()}`,
      );
      setItems(res.items);
      setTotal(res.total);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }, [status, trackingCode, clientCode, withoutClient]);

  useEffect(() => {
    void load();
  }, [load]);

  async function patchStatus(id: string, next: string) {
    setUpdating(id);
    setErr('');
    try {
      await apiFetch(`/orders/${id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status: next }),
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setUpdating(null);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Заказы</h1>
      <p className="mt-1 text-slate-600">Фильтры и смена статуса</p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      <div className="mt-4 flex flex-wrap gap-3 rounded-xl border border-slate-200 bg-white p-4">
        <select
          className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">Все статусы</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <input
          className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
          placeholder="Трек"
          value={trackingCode}
          onChange={(e) => setTrackingCode(e.target.value)}
        />
        <input
          className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
          placeholder="Код клиента"
          value={clientCode}
          onChange={(e) => setClientCode(e.target.value)}
        />
        <button
          type="button"
          onClick={() => void load()}
          className="rounded-lg bg-slate-600 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700"
        >
          {loading ? '…' : 'Обновить'}
        </button>
        <label className="inline-flex items-center gap-2 text-sm text-slate-700">
          <input
            type="checkbox"
            checked={withoutClient}
            onChange={(e) => setWithoutClient(e.target.checked)}
          />
          Без клиента в базе
        </label>
      </div>

      <p className="mt-2 text-sm text-slate-700">Всего: {total}</p>

      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="w-full min-w-[800px] text-left text-sm text-slate-900">
          <thead className="bg-slate-200 text-slate-800">
            <tr>
              <th className="px-3 py-2">Трек</th>
              <th className="px-3 py-2">Статус</th>
              <th className="px-3 py-2">Клиент</th>
              <th className="px-3 py-2">Вес</th>
              <th className="px-3 py-2">Оплата</th>
              <th className="px-3 py-2">Сменить статус</th>
            </tr>
          </thead>
          <tbody>
            {items.map((o) => (
              <tr key={o.id} className="border-t border-slate-200 bg-white">
                <td className="px-3 py-2 font-mono text-slate-900">{o.trackingCode}</td>
                <td className="px-3 py-2 text-slate-800">{o.status}</td>
                <td className="px-3 py-2 text-slate-900">
                  {o.client
                    ? `${o.client.clientCode ?? '—'} / ${o.client.name ?? '—'}`
                    : o.guestName || o.guestPhone
                      ? `Ручной: ${o.guestName ?? '—'} / ${o.guestPhone ?? '—'}`
                      : '—'}
                </td>
                <td className="px-3 py-2 text-slate-800">{o.weightGrams ?? '—'}</td>
                <td className="px-3 py-2 text-slate-800">{o.isPaid ? 'да' : 'нет'}</td>
                <td className="px-3 py-2">
                  <select
                    className="max-w-[200px] rounded border border-slate-300 bg-white px-2 py-1 text-xs text-slate-900"
                    value={o.status}
                    disabled={updating === o.id}
                    onChange={(e) => {
                      if (e.target.value !== o.status) {
                        void patchStatus(o.id, e.target.value);
                      }
                    }}
                  >
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
