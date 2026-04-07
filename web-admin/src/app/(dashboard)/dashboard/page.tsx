'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from '@/lib/api';

type Summary = {
  qrCode?: string;
  stats: {
    all: number;
    receivedChina: number;
    inTransit: number;
    sorting: number;
    readyPickup: number;
    withCourier: number;
    unpaid: number;
    completed: number;
  };
};

type AuditRow = {
  id: string;
  action: string;
  entityType: string;
  createdAt: string;
};

export default function DashboardPage() {
  const [summary, setSummary] = useState<Summary | null>(null);
  const [audit, setAudit] = useState<AuditRow[]>([]);
  const [err, setErr] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [s, a] = await Promise.all([
          apiFetch<Summary>('/orders/summary'),
          apiFetch<AuditRow[]>('/admin/audit?limit=8'),
        ]);
        if (!cancelled) {
          setSummary(s);
          setAudit(a);
        }
      } catch (e) {
        if (!cancelled) setErr(e instanceof Error ? e.message : 'Ошибка');
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const st = summary?.stats;

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Дашборд</h1>
      <p className="mt-1 text-slate-600">Сводка по заказам и последние действия</p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          ['Все заказы', st?.all],
          ['В Китае', st?.receivedChina],
          ['В пути', st?.inTransit],
          ['К выдаче', st?.readyPickup],
          ['С курьером', st?.withCourier],
          ['Неоплаченные', st?.unpaid],
          ['Завершённые', st?.completed],
          ['Сортировка', st?.sorting],
        ].map(([label, v]) => (
          <div
            key={String(label)}
            className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
          >
            <div className="text-sm text-slate-500">{label}</div>
            <div className="mt-1 text-2xl font-bold text-slate-900">{v ?? '—'}</div>
          </div>
        ))}
      </div>

      <div className="mt-8">
        <h2 className="text-lg font-semibold text-slate-900">Последние события (аудит)</h2>
        <div className="mt-3 overflow-hidden rounded-xl border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th className="px-4 py-2">Время</th>
                <th className="px-4 py-2">Действие</th>
                <th className="px-4 py-2">Сущность</th>
              </tr>
            </thead>
            <tbody>
              {audit.map((row) => (
                <tr key={row.id} className="border-t border-slate-100">
                  <td className="px-4 py-2 text-slate-600">
                    {new Date(row.createdAt).toLocaleString('ru-RU')}
                  </td>
                  <td className="px-4 py-2">{row.action}</td>
                  <td className="px-4 py-2">{row.entityType}</td>
                </tr>
              ))}
              {audit.length === 0 && (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-slate-500">
                    Нет записей
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
