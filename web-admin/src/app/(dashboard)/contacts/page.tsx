'use client';

import { useCallback, useEffect, useState } from 'react';
import { apiFetch } from '@/lib/api';

type Contact = {
  id: string;
  key: string;
  label: string;
  usernameOrPhone: string;
  appUrl: string;
  webUrl: string;
};

export default function ContactsPage() {
  const [items, setItems] = useState<Contact[]>([]);
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const data = await apiFetch<Contact[]>('/tariffs/support-contacts');
      setItems(data);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function save(c: Contact) {
    setErr('');
    try {
      await apiFetch(`/admin/support-contacts/${encodeURIComponent(c.key)}`, {
        method: 'PATCH',
        body: JSON.stringify({
          label: c.label,
          usernameOrPhone: c.usernameOrPhone,
          appUrl: c.appUrl,
          webUrl: c.webUrl,
        }),
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  async function remove(key: string) {
    if (!confirm(`Удалить контакт ${key}?`)) return;
    setErr('');
    try {
      await apiFetch(`/admin/support-contacts/${encodeURIComponent(key)}`, {
        method: 'DELETE',
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  async function create(e: React.FormEvent) {
    e.preventDefault();
    const fd = new FormData(e.target as HTMLFormElement);
    const key = String(fd.get('key') ?? '').trim();
    const label = String(fd.get('label') ?? '').trim();
    const usernameOrPhone = String(fd.get('usernameOrPhone') ?? '').trim();
    const appUrl = String(fd.get('appUrl') ?? '').trim();
    const webUrl = String(fd.get('webUrl') ?? '').trim();
    setErr('');
    try {
      await apiFetch('/admin/support-contacts', {
        method: 'POST',
        body: JSON.stringify({
          key,
          label,
          usernameOrPhone,
          appUrl,
          webUrl,
        }),
      });
      (e.target as HTMLFormElement).reset();
      setShowCreate(false);
      await load();
    } catch (err) {
      setErr(err instanceof Error ? err.message : 'Ошибка');
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Контакты поддержки</h1>
      <p className="mt-1 text-slate-600">Ссылки для Instagram / Telegram / WhatsApp</p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      {loading ? (
        <p className="mt-6">Загрузка…</p>
      ) : (
        <div className="mt-6 space-y-6">
          {items.map((c) => (
            <ContactRow key={c.id} initial={c} onSave={save} onDelete={remove} />
          ))}
        </div>
      )}

      <div className="mt-8">
        {!showCreate ? (
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="inline-flex h-10 items-center justify-center rounded-lg bg-slate-800 px-4 text-sm font-medium text-white hover:bg-slate-900"
          >
            + Новый контакт
          </button>
        ) : (
          <form
            onSubmit={create}
            className="space-y-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-4"
          >
            <h3 className="font-semibold">Новый контакт</h3>
            <div className="grid gap-2 sm:grid-cols-2">
              <input name="key" className="rounded border px-3 py-2 text-sm" placeholder="key" required />
              <input name="label" className="rounded border px-3 py-2 text-sm" placeholder="Подпись" required />
              <input
                name="usernameOrPhone"
                className="rounded border px-3 py-2 text-sm"
                placeholder="Username / телефон"
                required
              />
              <input name="appUrl" className="rounded border px-3 py-2 text-sm" placeholder="app URL" required />
              <input
                name="webUrl"
                className="rounded border px-3 py-2 text-sm sm:col-span-2"
                placeholder="web URL"
                required
              />
            </div>
            <div className="flex flex-wrap gap-2">
              <button type="submit" className="rounded-lg bg-slate-800 px-4 py-2 text-sm text-white">
                Создать
              </button>
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700"
              >
                Отмена
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

function ContactRow({
  initial,
  onSave,
  onDelete,
}: {
  initial: Contact;
  onSave: (c: Contact) => void;
  onDelete: (key: string) => void;
}) {
  const [c, setC] = useState(initial);
  const [editing, setEditing] = useState(false);
  useEffect(() => {
    setC(initial);
    setEditing(false);
  }, [initial]);

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <span className="font-mono font-semibold">{c.key}</span>
        <div className="flex items-center gap-3">
          {!editing && (
            <button
              type="button"
              onClick={() => setEditing(true)}
              className="text-sm text-slate-700 hover:underline"
            >
              Изменить
            </button>
          )}
          <button type="button" onClick={() => onDelete(c.key)} className="text-sm text-orange-600">
            Удалить
          </button>
        </div>
      </div>
      {!editing ? (
        <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
          <div><span className="text-slate-500">label:</span> {c.label}</div>
          <div><span className="text-slate-500">usernameOrPhone:</span> {c.usernameOrPhone}</div>
          <div className="sm:col-span-2"><span className="text-slate-500">appUrl:</span> {c.appUrl}</div>
          <div className="sm:col-span-2"><span className="text-slate-500">webUrl:</span> {c.webUrl}</div>
        </div>
      ) : (
        <>
          <div className="mt-3 grid gap-2 sm:grid-cols-2">
            {(['label', 'usernameOrPhone', 'appUrl', 'webUrl'] as const).map((field) => (
              <label key={field} className="block text-sm">
                <span className="text-slate-600">{field}</span>
                <input
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-1"
                  value={c[field]}
                  onChange={(e) => setC({ ...c, [field]: e.target.value })}
                />
              </label>
            ))}
          </div>
          <div className="mt-3 flex items-center gap-3">
            <button
              type="button"
              onClick={() => onSave(c)}
              className="rounded-lg bg-orange-600 px-4 py-2 text-sm text-white"
            >
              Сохранить
            </button>
            <button
              type="button"
              onClick={() => {
                setC(initial);
                setEditing(false);
              }}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700"
            >
              Отмена
            </button>
          </div>
        </>
      )}
    </div>
  );
}
