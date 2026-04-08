'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { apiFetch } from '@/lib/api';

type LookupResponse = {
  found: boolean;
  userId?: string;
  clientCode?: string;
  name?: string;
  phone?: string;
};

type AdminOrder = {
  id: string;
  trackingCode: string;
  status: string;
  isPaid: boolean;
  createdAt: string;
  updatedAt: string;
  client: {
    id: string;
    name: string;
    phone: string;
    clientCode: string | null;
  } | null;
};

type AdminOrdersResponse = {
  items: AdminOrder[];
};

type FilterKind = 'all' | 'ready' | 'notReady';

const NOT_READY_STATUSES = new Set([
  'received_china',
  'in_transit',
  'sorting',
  'with_courier',
]);

export default function QrScanPage() {
  const [scanOpen, setScanOpen] = useState(false);
  const [scanErr, setScanErr] = useState('');
  const [hint, setHint] = useState('');
  const [manualCode, setManualCode] = useState('');

  const [client, setClient] = useState<Required<Pick<LookupResponse, 'userId' | 'clientCode' | 'name' | 'phone'>> | null>(null);
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [err, setErr] = useState('');
  const [filter, setFilter] = useState<FilterKind>('all');

  const scannerRef = useRef<{ stop: () => Promise<void>; clear: () => void } | null>(null);

  const filteredOrders = useMemo(() => {
    if (filter === 'all') return orders;
    if (filter === 'ready') return orders.filter((o) => o.status === 'ready_pickup');
    return orders.filter((o) => NOT_READY_STATUSES.has(o.status));
  }, [orders, filter]);

  const loadClientOrders = useCallback(async (clientCodeRaw: string) => {
    const clientCode = extractClientCode(clientCodeRaw);
    if (!clientCode) {
      setErr('Не удалось распознать clientCode из QR');
      return;
    }
    setErr('');
    setLoadingOrders(true);
    try {
      const lookup = await apiFetch<LookupResponse>(`/client-codes/${encodeURIComponent(clientCode)}`);
      if (!lookup.found || !lookup.userId || !lookup.clientCode) {
        throw new Error('Клиент не найден по этому QR');
      }
      setClient({
        userId: lookup.userId,
        clientCode: lookup.clientCode,
        name: lookup.name ?? 'Без имени',
        phone: lookup.phone ?? '—',
      });
      const res = await apiFetch<AdminOrdersResponse>(
        `/admin/orders?take=300&clientCode=${encodeURIComponent(lookup.clientCode)}`,
      );
      setOrders(res.items);
    } catch (e) {
      setClient(null);
      setOrders([]);
      setErr(e instanceof Error ? e.message : 'Ошибка загрузки товаров');
    } finally {
      setLoadingOrders(false);
    }
  }, []);

  const stopScanner = useCallback(async () => {
    const scanner = scannerRef.current;
    if (!scanner) return;
    try {
      await scanner.stop();
    } catch {
      // ignore
    }
    try {
      scanner.clear();
    } catch {
      // ignore
    }
    scannerRef.current = null;
  }, []);

  useEffect(() => {
    return () => {
      void stopScanner();
    };
  }, [stopScanner]);

  async function startScanner() {
    setScanErr('');
    setHint('');
    if (typeof window !== 'undefined' && !window.isSecureContext) {
      setScanErr(
        'На телефоне камера в браузере работает только по HTTPS. Сейчас открыт HTTP.',
      );
      setHint('Используйте HTTPS-туннель или введите код клиента вручную ниже.');
      return;
    }
    setScanOpen(true);
    try {
      const lib = await import('html5-qrcode');
      const scanner = new lib.Html5Qrcode('client-qr-reader');
      scannerRef.current = scanner;
      await scanner.start(
        { facingMode: 'environment' },
        { fps: 10, qrbox: { width: 260, height: 260 } },
        (decodedText: string) => {
          setScanOpen(false);
          void stopScanner();
          void loadClientOrders(decodedText);
        },
        () => {
          // ignore frame errors
        },
      );
    } catch (e) {
      setScanOpen(false);
      setScanErr(e instanceof Error ? e.message : 'Не удалось запустить сканер');
      await stopScanner();
    }
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">QR сканирование</h1>
        <p className="mt-1 text-slate-600">
          Сканируйте QR клиента и смотрите его товары с фильтрами выдачи
        </p>
      </div>

      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => {
              if (scanOpen) {
                setScanOpen(false);
                void stopScanner();
              } else {
                void startScanner();
              }
            }}
            className="rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700"
          >
            {scanOpen ? 'Остановить сканер' : 'Сканировать QR-код'}
          </button>
          <input
            value={manualCode}
            onChange={(e) => setManualCode(e.target.value)}
            placeholder="Или вставьте clientCode / QR строку"
            className="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
          <button
            type="button"
            onClick={() => void loadClientOrders(manualCode)}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
          >
            Найти
          </button>
        </div>

        {scanErr && <p className="mt-2 text-sm text-orange-700">{scanErr}</p>}
        {hint && <p className="mt-1 text-xs text-slate-500">{hint}</p>}

        {scanOpen && (
          <div
            id="client-qr-reader"
            className="mt-3 w-full max-w-md overflow-hidden rounded-xl border"
          />
        )}
      </section>

      {err && (
        <div className="rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">{err}</div>
      )}

      {client && (
        <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs uppercase tracking-wide text-slate-500">Клиент</p>
              <p className="text-lg font-bold text-slate-900">{client.name}</p>
              <p className="text-sm text-slate-600">{client.phone}</p>
              <p className="mt-1 font-mono text-sm text-orange-700">{client.clientCode}</p>
            </div>
            <div className="flex gap-2">
              <FilterButton
                active={filter === 'all'}
                label={`Все товары (${orders.length})`}
                onClick={() => setFilter('all')}
              />
              <FilterButton
                active={filter === 'ready'}
                label={`Готовые (${orders.filter((o) => o.status === 'ready_pickup').length})`}
                onClick={() => setFilter('ready')}
              />
              <FilterButton
                active={filter === 'notReady'}
                label={`Не готовые (${orders.filter((o) => NOT_READY_STATUSES.has(o.status)).length})`}
                onClick={() => setFilter('notReady')}
              />
            </div>
          </div>

          {loadingOrders ? (
            <p className="mt-4 text-slate-600">Загрузка товаров...</p>
          ) : filteredOrders.length === 0 ? (
            <p className="mt-4 text-slate-600">Товары по выбранному фильтру не найдены.</p>
          ) : (
            <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
              {filteredOrders.map((o) => (
                <article
                  key={o.id}
                  className="rounded-xl border border-slate-200 bg-slate-50 p-3"
                >
                  <div className="flex items-start justify-between gap-2">
                    <p className="font-mono text-sm font-semibold text-slate-900">
                      {o.trackingCode}
                    </p>
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        o.status === 'ready_pickup'
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-orange-100 text-orange-700'
                      }`}
                    >
                      {statusLabel(o.status)}
                    </span>
                  </div>
                  <p className="mt-2 text-xs text-slate-500">
                    Принят: {formatDate(o.createdAt)}
                  </p>
                  <p className="text-xs text-slate-500">Обновлён: {formatDate(o.updatedAt)}</p>
                  <p className="mt-2 text-xs text-slate-600">
                    Оплата: {o.isPaid ? 'Оплачен' : 'Не оплачен'}
                  </p>
                </article>
              ))}
            </div>
          )}
        </section>
      )}
    </div>
  );
}

function FilterButton({
  active,
  label,
  onClick,
}: {
  active: boolean;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-lg px-3 py-2 text-xs font-medium ${
        active
          ? 'bg-orange-600 text-white'
          : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
      }`}
    >
      {label}
    </button>
  );
}

function extractClientCode(input: string): string {
  const raw = input.trim();
  if (!raw) return '';
  const maybeDirect = raw.toUpperCase().replace(/\s+/g, '');
  if (/^[A-Z]{2}\d{3}$/.test(maybeDirect)) return maybeDirect;
  const parts = raw.split('/').filter((p) => p.length > 0);
  const last = (parts[parts.length - 1] ?? raw).toUpperCase();
  if (/^[A-Z]{2}\d{3}$/.test(last)) return last;
  return '';
}

function statusLabel(status: string): string {
  switch (status) {
    case 'received_china':
      return 'Получено в Китае';
    case 'in_transit':
      return 'В пути';
    case 'sorting':
      return 'Сортировка';
    case 'ready_pickup':
      return 'Готово к выдаче';
    case 'with_courier':
      return 'Передан курьеру';
    case 'completed':
      return 'Получен';
    default:
      return status;
  }
}

function formatDate(value: string): string {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  const two = (n: number) => (n < 10 ? `0${n}` : `${n}`);
  return `${two(d.getDate())}.${two(d.getMonth() + 1)}.${d.getFullYear()} ${two(
    d.getHours(),
  )}:${two(d.getMinutes())}`;
}
