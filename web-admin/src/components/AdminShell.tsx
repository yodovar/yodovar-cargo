'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { clearTokens } from '@/lib/api';

const links = [
  { href: '/dashboard', label: 'Дашборд' },
  { href: '/qr-scan', label: 'QR сканирование' },
  { href: '/intake', label: 'Принято в Китае' },
  { href: '/in-transit', label: 'В пути' },
  { href: '/sorting', label: 'Сортировка' },
  { href: '/ready-pickup', label: 'Готово к выдаче' },
  { href: '/orders', label: 'Заказы' },
  { href: '/channels', label: 'Канал' },
  { href: '/users', label: 'Пользователи' },
  { href: '/tariffs', label: 'Тарифы' },
  { href: '/contacts', label: 'Контакты' },
  { href: '/pickup-points', label: 'Пункты выдачи' },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    setMobileMenuOpen(false);
  }, [pathname]);

  return (
    <div className="flex min-h-screen bg-slate-100">
      <aside className="hidden w-56 shrink-0 border-r border-slate-200 bg-white px-3 py-6 md:block">
        <div className="mb-8 px-2">
          <div className="flex items-center gap-2">
            <Image src="/logo/logo.png" alt="Insof Cargo" width={28} height={28} />
            <div className="text-lg font-bold text-orange-600">Insof Cargo</div>
          </div>
          <div className="text-xs text-slate-500">Админ-панель</div>
        </div>
        <nav className="flex flex-col gap-1">
          {links.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className={`rounded-lg px-3 py-2 text-sm font-medium ${
                pathname === l.href
                  ? 'bg-orange-50 text-orange-700'
                  : 'text-slate-700 hover:bg-slate-50'
              }`}
            >
              {l.label}
            </Link>
          ))}
        </nav>
        <button
          type="button"
          onClick={() => {
            clearTokens();
            router.replace('/login');
          }}
          className="mt-8 w-full rounded-lg px-3 py-2 text-left text-sm text-slate-500 hover:bg-slate-50"
        >
          Выйти
        </button>
      </aside>
      <main className="min-w-0 flex-1 p-4 md:p-6">
        <div className="mb-4 rounded-xl border border-slate-300 bg-white p-3 shadow-sm md:hidden">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <Image src="/logo/logo.png" alt="Insof Cargo" width={24} height={24} />
              <div className="text-base font-bold text-orange-700">Insof Cargo</div>
            </div>
            <button
              type="button"
              onClick={() => setMobileMenuOpen((v) => !v)}
              className="rounded-lg border border-slate-300 bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-800"
            >
              {mobileMenuOpen ? 'Закрыть' : '☰ Разделы'}
            </button>
          </div>
          {mobileMenuOpen && (
            <nav className="mt-3 grid grid-cols-2 gap-2">
              {links.map((l) => (
                <Link
                  key={l.href}
                  href={l.href}
                  className={`rounded-lg px-3 py-2 text-center text-sm font-semibold ${
                    pathname === l.href
                      ? 'bg-orange-600 text-white'
                      : 'border border-slate-300 bg-slate-50 text-slate-800'
                  }`}
                >
                  {l.label}
                </Link>
              ))}
              <button
                type="button"
                onClick={() => {
                  clearTokens();
                  router.replace('/login');
                }}
                className="col-span-2 rounded-lg border border-orange-300 bg-orange-50 px-3 py-2 text-sm font-semibold text-orange-700"
              >
                Выйти
              </button>
            </nav>
          )}
        </div>
        {children}
      </main>
    </div>
  );
}
