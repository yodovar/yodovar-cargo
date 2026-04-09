'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { clearTokens } from '@/lib/api';

const links = [
  { href: '/dashboard', label: 'Дашборд' },
  { href: '/qr-scan', label: 'QR сканирование' },
  { href: '/intake', label: 'Принято в Китае' },
  { href: '/in-transit', label: 'В пути' },
  { href: '/sorting', label: 'Сортировка' },
  { href: '/ready-pickup', label: 'Готово к выдаче' },
  { href: '/orders', label: 'Заказы' },
  { href: '/users', label: 'Пользователи' },
  { href: '/tariffs', label: 'Тарифы' },
  { href: '/contacts', label: 'Контакты' },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

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
        <div className="mb-4 rounded-xl border border-slate-200 bg-white p-3 md:hidden">
          <div className="mb-2 flex items-center gap-2">
            <Image src="/logo/logo.png" alt="Insof Cargo" width={24} height={24} />
            <div className="text-base font-bold text-orange-600">Insof Cargo</div>
          </div>
          <nav className="flex gap-2 overflow-x-auto pb-1">
            {links.map((l) => (
              <Link
                key={l.href}
                href={l.href}
                className={`whitespace-nowrap rounded-lg px-3 py-2 text-sm font-medium ${
                  pathname === l.href
                    ? 'bg-orange-50 text-orange-700'
                    : 'text-slate-700 hover:bg-slate-50'
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
              className="whitespace-nowrap rounded-lg px-3 py-2 text-sm text-slate-500 hover:bg-slate-50"
            >
              Выйти
            </button>
          </nav>
        </div>
        {children}
      </main>
    </div>
  );
}
