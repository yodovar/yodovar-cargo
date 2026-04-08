'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apiFetch, clearTokens, getAccessToken, refreshSession } from '@/lib/api';

export function RequireAuth({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    async function checkAuth() {
      const token = getAccessToken();
      if (!token) {
        router.replace('/login');
        return;
      }

      try {
        await apiFetch<{ role: string }>('/me');
        if (!cancelled) setReady(true);
      } catch {
        const restored = await refreshSession();
        if (!restored) {
          clearTokens();
          router.replace('/login');
          return;
        }
        try {
          await apiFetch<{ role: string }>('/me');
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
