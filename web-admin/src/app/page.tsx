'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { clearTokens, getAccessToken, refreshSession } from '@/lib/api';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    async function resolveRoute() {
      if (getAccessToken()) {
        router.replace('/dashboard');
        return;
      }
      const restored = await refreshSession();
      if (cancelled) return;
      if (restored) {
        router.replace('/dashboard');
      } else {
        clearTokens();
        router.replace('/login');
      }
    }
    void resolveRoute();
    return () => {
      cancelled = true;
    };
  }, [router]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 text-slate-600">
      Загрузка…
    </div>
  );
}
