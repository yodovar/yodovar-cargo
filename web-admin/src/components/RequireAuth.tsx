'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apiFetch, clearTokens, getAccessToken, refreshSession } from '@/lib/api';

export function RequireAuth({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const withTimeout = async <T,>(promise: Promise<T>, ms = 5000) => {
      return await Promise.race<T | null>([
        promise,
        new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
      ]);
    };
    async function checkAuth() {
      const token = getAccessToken();
      if (!token) {
        router.replace('/login');
        return;
      }

      try {
        const me = await withTimeout(apiFetch<{ role: string }>('/me'), 5000);
        if (!me) throw new Error('timeout');
        if (!cancelled) setReady(true);
      } catch {
        const restored = await withTimeout(refreshSession(), 5000);
        if (!restored) {
          clearTokens();
          router.replace('/login');
          return;
        }
        try {
          const me = await withTimeout(apiFetch<{ role: string }>('/me'), 5000);
          if (!me) throw new Error('timeout');
          if (!cancelled) setReady(true);
        } catch {
          clearTokens();
          router.replace('/login');
        }
      }
    }
    void checkAuth();
    return () => {
      cancelled = true;
    };
  }, [router]);

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-slate-600">Загрузка…</p>
      </div>
    );
  }

  return <>{children}</>;
}
