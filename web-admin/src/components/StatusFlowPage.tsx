'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { apiFetch } from '@/lib/api';

type ClientLookup = {
  id: string;
  name: string;
  phone: string;
  clientCode: string;
};

type LookupByCodeResponse = {
  found: boolean;
  userId?: string;
  name?: string;
  phone?: string;
  clientCode?: string;
};

type UsersResponse = {
  items: Array<{
    id: string;
    name: string;
    phone: string;
    clientCode: string | null;
    role: string;
  }>;
};

type AdminOrder = {
  id: string;
  trackingCode: string;
  status: string;
};

type OrdersResponse = {
  items: AdminOrder[];
};

type FlowResult = {
  trackingCode: string;
  ok: boolean;
  message: string;
};

type Mode = 'intake' | 'status-update';

export function StatusFlowPage({
  title,
  subtitle,
  mode,
  targetStatus,
}: {
  title: string;
  subtitle: string;
  mode: Mode;
  targetStatus?: string;
}) {
  const [search, setSearch] = useState('');
  const [results, setResults] = useState<ClientLookup[]>([]);
  const [selected, setSelected] = useState<ClientLookup | null>(null);
  const [searching, setSearching] = useState(false);
  const [searchErr, setSearchErr] = useState('');

  const [trackingInput, setTrackingInput] = useState('');
  const [trackingCodes, setTrackingCodes] = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [resultLog, setResultLog] = useState<FlowResult[]>([]);
  const [commonErr, setCommonErr] = useState('');
  const isStatusOnly = mode === 'status-update';

  const normalizedSearch = useMemo(() => search.trim(), [search]);

  const runLookup = useCallback(async () => {
    if (isStatusOnly) return;
    if (!normalizedSearch) {
      setResults([]);
      setSearchErr('');
      return;
    }
    setSearching(true);
    setSearchErr('');
    try {
      const list: ClientLookup[] = [];
      const maybeCode = normalizedSearch.toUpperCase().replace(/\s+/g, '');

      if (/^[A-Z]{2}\d{3}$/.test(maybeCode)) {
        const byCode = await apiFetch<LookupByCodeResponse>(
          `/client-codes/${encodeURIComponent(maybeCode)}`,
        );
        if (byCode.found && byCode.userId && byCode.clientCode) {
          list.push({
            id: byCode.userId,
            name: byCode.name ?? 'Без имени',
            phone: byCode.phone ?? '',
            clientCode: byCode.clientCode,
          });
        }
      }

      const users = await apiFetch<UsersResponse>(
        `/admin/users?take=20&role=client&q=${encodeURIComponent(normalizedSearch)}`,
      );
      for (const u of users.items) {
        if (!u.clientCode) continue;
        if (u.role !== 'client') continue;
        if (list.some((x) => x.id === u.id)) continue;
        list.push({
          id: u.id,
          name: u.name || 'Без имени',
          phone: u.phone,
          clientCode: u.clientCode,
        });
      }
      setResults(list);
      if (list.length === 0) setSearchErr('Клиент не найден');
    } catch (e) {
      setSearchErr(e instanceof Error ? e.message : 'Ошибка поиска');
    } finally {
      setSearching(false);
    }
  }, [isStatusOnly, normalizedSearch]);

  useEffect(() => {
    if (isStatusOnly) return;
    const t = setTimeout(() => {
      void runLookup();
    }, 280);
    return () => clearTimeout(t);
  }, [isStatusOnly, runLookup]);

  function addTracking(raw: string) {
    const code = raw.trim().toUpperCase();
    if (!code || code.length < 3) return;
    setTrackingCodes((prev) => (prev.includes(code) ? prev : [...prev, code]));
  }

  function addFromInput() {
    const parts = trackingInput
      .split(/[\n,\s]+/)
      .map((x) => x.trim())
      .filter(Boolean);
    parts.forEach(addTracking);
    setTrackingInput('');
  }

  async function patchStatusForTracking(trackingCode: string, status: string) {
    const q = new URLSearchParams();
    q.set('take', '20');
    q.set('trackingCode', trackingCode);
    const res = await apiFetch<OrdersResponse>(`/admin/orders?${q.toString()}`);
    const exact = res.items.find(
      (o) => o.trackingCode.trim().toUpperCase() === trackingCode,
    );
    if (!exact) {
      throw new Error('Товар не найден. Сначала добавьте его на странице "Принято в Китае".');
    }
    await apiFetch(`/orders/${exact.id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  async function submitAll() {
    if (!isStatusOnly && !selected) {
      setCommonErr('Сначала выберите клиента');
      return;
    }
    if (trackingCodes.length === 0) {
      setCommonErr('Добавьте хотя бы один трек-код');
      return;
    }
    setSubmitting(true);
    setCommonErr('');
    const out: FlowResult[] = [];
    for (const code of trackingCodes) {
      try {
        if (mode === 'intake') {
          await apiFetch('/warehouse-cn/intake', {
            method: 'POST',
            body: JSON.stringify({
              trackingCode: code,
              clientCode: selected.clientCode,
            }),
          });
          out.push({ trackingCode: code, ok: true, message: 'Добавлено в Китае' });
        } else {
          await patchStatusForTracking(code, targetStatus ?? '');
          out.push({ trackingCode: code, ok: true, message: `Статус: ${targetStatus}` });
        }
      } catch (e) {
        out.push({
          trackingCode: code,
          ok: false,
          message: e instanceof Error ? e.message : 'Ошибка',
        });
      }
    }
    setResultLog(out);
    setTrackingCodes([]);
    setSubmitting(false);
  }

  function pickClient(c: ClientLookup) {
    setSelected(c);
    setSearch(c.clientCode);
    setResults([]);
    setSearchErr('');
    setResultLog([]);
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
        <p className="mt-1 text-slate-600">{subtitle}</p>
      </div>

      {commonErr && (
        <div className="rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {commonErr}
        </div>
      )}

      {!isStatusOnly && (
        <section className="rounded-xl border border-slate-200 bg-white p-4">
          <label className="block text-sm font-medium text-slate-700">
            Клиент (код или номер телефона)
          </label>
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setSelected(null);
            }}
            placeholder="Например: AP789 или +992..."
            className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2"
          />
          <p className="mt-1 text-xs text-slate-500">{searching ? 'Поиск...' : 'AJAX-поиск по базе'}</p>
          {searchErr && <p className="mt-2 text-sm text-orange-700">{searchErr}</p>}
          {results.length > 0 && (
            <div className="mt-3 overflow-hidden rounded-lg border border-slate-200">
              {results.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => pickClient(c)}
                  className="flex w-full items-center justify-between border-b border-slate-100 px-3 py-2 text-left last:border-b-0 hover:bg-slate-50"
                >
                  <span className="text-sm">
                    {c.name} · {c.phone}
                  </span>
                  <span className="font-mono text-xs text-slate-600">{c.clientCode}</span>
                </button>
              ))}
            </div>
          )}
        </section>
      )}

      <section className="rounded-xl border border-slate-200 bg-white p-4">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-lg font-semibold text-slate-900">Трек-коды</h2>
          {selected ? (
            <span className="rounded bg-emerald-50 px-2 py-1 text-xs text-emerald-700">
              Клиент: {selected.name} ({selected.clientCode})
            </span>
          ) : (
            <span className="text-xs text-slate-500">
              {isStatusOnly ? 'Клиент определится по трек-коду' : 'Клиент не выбран'}
            </span>
          )}
        </div>

        <div className="mt-3 flex gap-2">
          <input
            value={trackingInput}
            onChange={(e) => setTrackingInput(e.target.value)}
            placeholder="Вставьте трек-коды через пробел/новую строку"
            className="flex-1 rounded-lg border border-slate-300 px-3 py-2"
          />
          <button
            type="button"
            onClick={addFromInput}
            className="rounded-lg bg-slate-700 px-4 py-2 text-sm text-white hover:bg-slate-800"
          >
            Добавить
          </button>
        </div>

        <BarcodeScannerButton onDetected={addTracking} />

        <div className="mt-4 rounded-lg border border-slate-200 bg-slate-50 p-3">
          <p className="text-sm font-medium text-slate-700">
            Добавлено трек-кодов: {trackingCodes.length}
          </p>
          {trackingCodes.length > 0 && (
            <div className="mt-2 flex flex-wrap gap-2">
              {trackingCodes.map((t) => (
                <span
                  key={t}
                  className="inline-flex items-center gap-1 rounded bg-white px-2 py-1 font-mono text-xs"
                >
                  {t}
                  <button
                    type="button"
                    className="text-slate-500 hover:text-red-600"
                    onClick={() => setTrackingCodes((prev) => prev.filter((x) => x !== t))}
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        <div className="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void submitAll()}
            disabled={submitting}
            className="rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700 disabled:opacity-50"
          >
            {submitting ? 'Сохранение...' : mode === 'intake' ? 'Добавить товары' : 'Обновить статус'}
          </button>
          {!isStatusOnly && (
            <button
              type="button"
              onClick={() => setSelected(null)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700"
            >
              Выбрать другого клиента
            </button>
          )}
        </div>

        {resultLog.length > 0 && (
          <div className="mt-4 rounded-lg border border-slate-200">
            {resultLog.map((r) => (
              <div
                key={r.trackingCode}
                className={`flex justify-between border-b border-slate-100 px-3 py-2 text-sm last:border-b-0 ${
                  r.ok ? 'bg-emerald-50/40' : 'bg-red-50/40'
                }`}
              >
                <span className="font-mono">{r.trackingCode}</span>
                <span>{r.message}</span>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function BarcodeScannerButton({ onDetected }: { onDetected: (text: string) => void }) {
  const [open, setOpen] = useState(false);
  const [err, setErr] = useState('');
  const [hint, setHint] = useState('');
  const scannerRef = useRef<{ stop: () => Promise<void>; clear: () => void } | null>(null);

  const stopScanner = useCallback(async () => {
    const scanner = scannerRef.current;
    if (!scanner) return;
    try {
      await scanner.stop();
    } catch {}
    try {
      scanner.clear();
    } catch {}
    scannerRef.current = null;
  }, []);

  useEffect(() => {
    return () => {
      void stopScanner();
    };
  }, [stopScanner]);

  async function startScanner() {
    setErr('');
    setHint('');
    if (typeof window !== 'undefined' && !window.isSecureContext) {
      setErr(
        'Камера недоступна в незащищенном HTTP-контексте. На телефоне откройте сайт по HTTPS или localhost.',
      );
      setHint('Для локальной сети используйте ручной ввод треков или HTTPS-туннель.');
      return;
    }
    setOpen(true);
    try {
      const lib = await import('html5-qrcode');
      const scanner = new lib.Html5Qrcode('barcode-reader');
      scannerRef.current = scanner;
      await scanner.start(
        { facingMode: 'environment' },
        { fps: 10, qrbox: { width: 260, height: 120 } },
        (decodedText: string) => {
          onDetected(decodedText);
          setOpen(false);
          void stopScanner();
        },
        () => {},
      );
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Не удалось запустить сканер');
      setOpen(false);
      await stopScanner();
    }
  }

  return (
    <div className="mt-3">
      <button
        type="button"
        onClick={() => {
          if (open) {
            setOpen(false);
            void stopScanner();
          } else {
            void startScanner();
          }
        }}
        className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
      >
        {open ? 'Остановить сканер' : 'Сканировать штрихкод'}
      </button>
      {err && <p className="mt-2 text-xs text-orange-700">{err}</p>}
      {hint && <p className="mt-1 text-xs text-slate-500">{hint}</p>}
      {open && <div id="barcode-reader" className="mt-3 w-full max-w-md overflow-hidden rounded-lg border" />}
    </div>
  );
}
