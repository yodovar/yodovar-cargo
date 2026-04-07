'use client';

import { useCallback, useEffect, useState } from 'react';
import { apiFetch } from '@/lib/api';

type Detail = { icon: string; text: string };

type Tariff = {
  key: string;
  title: string;
  pricePerKgUsd: number;
  pricePerCubicUsd: number;
  minChargeWeightG: number;
  etaDaysMin: number;
  etaDaysMax: number;
  details: Detail[];
};

export default function TariffsPage() {
  const [items, setItems] = useState<Tariff[]>([]);
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const data = await apiFetch<Tariff[]>('/tariffs');
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

  async function save(t: Tariff) {
    setErr('');
    try {
      await apiFetch(`/admin/tariffs/${encodeURIComponent(t.key)}`, {
        method: 'PATCH',
        body: JSON.stringify({
          title: t.title,
          pricePerKgUsd: t.pricePerKgUsd,
          pricePerCubicUsd: t.pricePerCubicUsd,
          minChargeWeightG: t.minChargeWeightG,
          etaDaysMin: t.etaDaysMin,
          etaDaysMax: t.etaDaysMax,
          details: t.details,
        }),
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  async function remove(key: string) {
    if (!confirm(`Удалить тариф ${key}?`)) return;
    setErr('');
    try {
      await apiFetch(`/admin/tariffs/${encodeURIComponent(key)}`, {
        method: 'DELETE',
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Тарифы</h1>
      <p className="mt-1 text-slate-600">Просмотр, правка и удаление</p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      {loading ? (
        <p className="mt-6 text-slate-600">Загрузка…</p>
      ) : (
        <div className="mt-6 space-y-8">
          {items.map((t) => (
            <TariffEditor key={t.key} initial={t} onSave={save} onDelete={remove} />
          ))}
        </div>
      )}

      <CreateTariffForm onCreated={() => void load()} onError={setErr} />
    </div>
  );
}

function TariffEditor({
  initial,
  onSave,
  onDelete,
}: {
  initial: Tariff;
  onSave: (t: Tariff) => void;
  onDelete: (key: string) => void;
}) {
  const [t, setT] = useState(initial);
  const [detailsJson, setDetailsJson] = useState(() =>
    JSON.stringify(initial.details, null, 2),
  );
  useEffect(() => {
    setT(initial);
    setDetailsJson(JSON.stringify(initial.details, null, 2));
  }, [initial]);

  function handleSave() {
    let details: Detail[];
    try {
      const parsed = JSON.parse(detailsJson) as unknown;
      if (!Array.isArray(parsed)) throw new Error('not array');
      details = parsed.map((item) => ({
        icon: typeof (item as { icon?: string })?.icon === 'string' ? (item as { icon: string }).icon : 'info',
        text: typeof (item as { text?: string })?.text === 'string' ? (item as { text: string }).text : '',
      }));
    } catch {
      alert('Некорректный JSON в блоке «Детали»');
      return;
    }
    onSave({ ...t, details });
  }

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="font-mono text-lg font-semibold text-slate-900">{t.key}</h2>
        <button
          type="button"
          onClick={() => onDelete(t.key)}
          className="text-sm text-orange-600 hover:underline"
        >
          Удалить
        </button>
      </div>
      <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <Field label="Название" value={t.title} onChange={(v) => setT({ ...t, title: v })} />
        <Field
          label="$/кг"
          type="number"
          value={String(t.pricePerKgUsd)}
          onChange={(v) => setT({ ...t, pricePerKgUsd: Number(v) })}
        />
        <Field
          label="$/м³"
          type="number"
          value={String(t.pricePerCubicUsd)}
          onChange={(v) => setT({ ...t, pricePerCubicUsd: Number(v) })}
        />
        <Field
          label="Мин. вес (г)"
          type="number"
          value={String(t.minChargeWeightG)}
          onChange={(v) => setT({ ...t, minChargeWeightG: Number(v) })}
        />
        <Field
          label="ETA min (дн)"
          type="number"
          value={String(t.etaDaysMin)}
          onChange={(v) => setT({ ...t, etaDaysMin: Number(v) })}
        />
        <Field
          label="ETA max (дн)"
          type="number"
          value={String(t.etaDaysMax)}
          onChange={(v) => setT({ ...t, etaDaysMax: Number(v) })}
        />
      </div>
      <label className="mt-4 block text-sm">
        <span className="text-slate-600">Детали (JSON-массив объектов icon / text)</span>
        <textarea
          className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 font-mono text-xs"
          rows={8}
          value={detailsJson}
          onChange={(e) => setDetailsJson(e.target.value)}
        />
      </label>
      <button
        type="button"
        onClick={handleSave}
        className="mt-3 rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700"
      >
        Сохранить
      </button>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) {
  return (
    <label className="block text-sm">
      <span className="text-slate-600">{label}</span>
      <input
        type={type}
        className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </label>
  );
}

function CreateTariffForm({
  onCreated,
  onError,
}: {
  onCreated: () => void;
  onError: (s: string) => void;
}) {
  const [key, setKey] = useState('');
  const [title, setTitle] = useState('');
  const [jsonDetails, setJsonDetails] = useState(
    '[{"icon":"scale","text":"Описание"}]',
  );

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    onError('');
    try {
      const details = JSON.parse(jsonDetails) as Detail[];
      await apiFetch('/admin/tariffs', {
        method: 'POST',
        body: JSON.stringify({
          key: key.trim(),
          title: title.trim(),
          pricePerKgUsd: 2.5,
          pricePerCubicUsd: 220,
          minChargeWeightG: 100,
          etaDaysMin: 14,
          etaDaysMax: 25,
          details,
        }),
      });
      setKey('');
      setTitle('');
      onCreated();
    } catch (err) {
      onError(err instanceof Error ? err.message : 'Ошибка');
    }
  }

  return (
    <div className="mt-10 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-4">
      <h3 className="font-semibold text-slate-900">Новый тариф</h3>
      <form onSubmit={submit} className="mt-3 space-y-3">
        <input
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          placeholder="key (латиница, уникальный)"
          value={key}
          onChange={(e) => setKey(e.target.value)}
          required
        />
        <input
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          placeholder="Название"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <textarea
          className="w-full rounded-lg border border-slate-300 px-3 py-2 font-mono text-xs"
          rows={4}
          value={jsonDetails}
          onChange={(e) => setJsonDetails(e.target.value)}
        />
        <button
          type="submit"
          className="rounded-lg bg-slate-800 px-4 py-2 text-sm text-white hover:bg-slate-900"
        >
          Создать (цены по умолчанию, отредактируйте после)
        </button>
      </form>
    </div>
  );
}
