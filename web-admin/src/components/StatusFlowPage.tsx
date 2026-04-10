'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { apiFetch } from '@/lib/api';

type ClientLookup = {
  id: string;
  name: string;
  phone: string;
  clientCode: string;
  /** false = клиент есть в базе, но кода ещё нет (после первого входа в приложение появится). */
  hasClientCode: boolean;
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
      setSearching(false);
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
            hasClientCode: true,
          });
        }
      }

      const qParam = normalizedSearch
        ? `&q=${encodeURIComponent(normalizedSearch)}`
        : '';
      const users = await apiFetch<UsersResponse>(
        `/admin/users?take=60&role=client${qParam}`,
      );
      for (const u of users.items) {
        if (u.role !== 'client') continue;
        if (list.some((x) => x.id === u.id)) continue;
        const code = u.clientCode?.trim() ?? '';
        list.push({
          id: u.id,
          name: u.name || 'Без имени',
          phone: u.phone,
          clientCode: code,
          hasClientCode: code.length > 0,
        });
      }
      setResults(list);
      if (list.length === 0 && normalizedSearch) {
        setSearchErr('Клиент не найден');
      }
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
    if (trackingCodes.length === 0) {
      setCommonErr('Добавьте хотя бы один трек-код');
      return;
    }
    const selectedClientCode = selected?.clientCode?.trim() ?? '';
    if (mode === 'intake' && selected && !selected.hasClientCode) {
      setCommonErr(
        'У клиента ещё нет кода выдачи. Пусть один раз войдёт в приложение или проверьте карточку в разделе «Пользователи».',
      );
      return;
    }
    if (mode === 'intake' && !selectedClientCode) {
      if (!normalizedSearch) {
        setCommonErr('Выберите клиента, либо введите имя/телефон в поле поиска');
        return;
      }
    }
    setSubmitting(true);
    setCommonErr('');
    const out: FlowResult[] = [];
    const rawGuest = normalizedSearch;
    const digits = rawGuest.replace(/\D/g, '');
    const guestPhone = digits.length >= 5 ? rawGuest : undefined;
    const guestName = digits.length >= 5 ? undefined : rawGuest;

    for (const code of trackingCodes) {
      try {
        if (mode === 'intake') {
          const body: Record<string, unknown> = {
            trackingCode: code,
            ...(selectedClientCode ? { clientCode: selectedClientCode } : {}),
            ...(selectedClientCode
              ? {}
              : {
                  ...(guestName ? { guestName } : {}),
                  ...(guestPhone ? { guestPhone } : {}),
                }),
          };
          await apiFetch('/warehouse-cn/intake', {
            method: 'POST',
            body: JSON.stringify(body),
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
    setSearch(c.clientCode || c.phone || c.name);
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
            Клиент (код/имя/телефон)
          </label>
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setSelected(null);
            }}
            placeholder="Например: SF0036, Furuzon, +992... (если не найден, будет ручной клиент)"
            className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2"
          />
          <p className="mt-1 text-xs text-slate-500">{searching ? 'Поиск...' : 'Поиск по базе'}</p>
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
                  <span
                    className={`font-mono text-xs ${c.hasClientCode ? 'text-slate-600' : 'text-orange-600'}`}
                  >
                    {c.hasClientCode ? c.clientCode : 'нет кода'}
                  </span>
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
            <span
              className={`rounded px-2 py-1 text-xs ${
                selected.hasClientCode
                  ? 'bg-emerald-50 text-emerald-700'
                  : 'bg-orange-50 text-orange-800'
              }`}
            >
              Клиент: {selected.name}
              {selected.hasClientCode ? ` (${selected.clientCode})` : ' — код не назначен'}
            </span>
          ) : (
            <span className="text-xs text-slate-500">
              {isStatusOnly
                ? 'Клиент определится по трек-коду'
                : normalizedSearch
                  ? `Ручной клиент: ${normalizedSearch}`
                  : 'Клиент не выбран'}
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
