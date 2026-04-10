'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { clearTokens, getAccessToken, refreshSession } from '@/lib/api';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    const withTimeout = async <T,>(promise: Promise<T>, ms = 5000) => {
      return await Promise.race<T | null>([
        promise,
        new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
      ]);
    };
    async function resolveRoute() {
      if (getAccessToken()) {
        router.replace('/dashboard');
        return;
      }
      const restored = await withTimeout(refreshSession(), 5000);
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
