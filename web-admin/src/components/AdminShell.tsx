'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { clearTokens } from '@/lib/api';

const links = [
  { href: '/dashboard', label: 'Дашборд' },
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
      <aside className="w-56 shrink-0 border-r border-slate-200 bg-white px-3 py-6">
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
      <main className="min-w-0 flex-1 p-6">{children}</main>
    </div>
  );
}
