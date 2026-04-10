'use client';

import { useCallback, useEffect, useState } from 'react';
import { apiFetch } from '@/lib/api';

const ROLES = ['client', 'worker_cn', 'worker_tj', 'admin'] as const;

type UserRow = {
  id: string;
  phone: string;
  name: string;
  role: string;
  clientCode: string | null;
  createdAt: string;
};

export default function UsersPage() {
  const [items, setItems] = useState<UserRow[]>([]);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState('');
  const [saving, setSaving] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const params = new URLSearchParams();
      params.set('take', '100');
      if (q.trim()) params.set('q', q.trim());
      if (roleFilter) params.set('role', roleFilter);
      const res = await apiFetch<{ items: UserRow[]; total: number }>(
        `/admin/users?${params.toString()}`,
      );
      setItems(res.items);
      setTotal(res.total);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }, [q, roleFilter]);

  useEffect(() => {
    void load();
  }, [load]);

  async function setRole(userId: string, role: string) {
    setSaving(userId);
    setErr('');
    try {
      await apiFetch(`/admin/users/${userId}/role`, {
        method: 'PATCH',
        body: JSON.stringify({ role }),
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setSaving(null);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Пользователи</h1>
      <p className="mt-1 text-slate-600">Поиск и назначение ролей</p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      <div className="mt-4 flex flex-wrap gap-3 rounded-xl border border-slate-200 bg-white p-4">
        <input
          className="min-w-[200px] flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
          placeholder="Телефон, имя, код клиента"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <select
          className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
        >
          <option value="">Все роли</option>
          {ROLES.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
        <button
          type="button"
          onClick={() => void load()}
          className="rounded-lg bg-slate-600 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700"
        >
          {loading ? '…' : 'Найти'}
        </button>
      </div>

      <p className="mt-2 text-sm text-slate-700">Всего: {total}</p>

      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="w-full min-w-[700px] text-left text-sm text-slate-900">
          <thead className="bg-slate-200 text-slate-800">
            <tr>
              <th className="px-3 py-2">Телефон</th>
              <th className="px-3 py-2">Имя</th>
              <th className="px-3 py-2">Код</th>
              <th className="px-3 py-2">Роль</th>
              <th className="px-3 py-2">Сменить роль</th>
            </tr>
          </thead>
          <tbody>
            {items.map((u) => (
              <tr key={u.id} className="border-t border-slate-200 bg-white">
                <td className="px-3 py-2 text-slate-900">{u.phone}</td>
                <td className="px-3 py-2 text-slate-800">{u.name || '—'}</td>
                <td className="px-3 py-2 font-mono text-slate-900">{u.clientCode ?? '—'}</td>
                <td className="px-3 py-2 text-slate-800">{u.role}</td>
                <td className="px-3 py-2">
                  <select
                    className="rounded border border-slate-300 bg-white px-2 py-1 text-xs text-slate-900"
                    value={u.role}
                    disabled={saving === u.id}
                    onChange={(e) => {
                      if (e.target.value !== u.role) {
                        void setRole(u.id, e.target.value);
                      }
                    }}
                  >
                    {ROLES.map((r) => (
                      <option key={r} value={r}>
                        {r}
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
