'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { getAccessToken } from '@/lib/api';

export function RequireAuth({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!getAccessToken()) {
      router.replace('/login');
      return;
    }
    setReady(true);
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
