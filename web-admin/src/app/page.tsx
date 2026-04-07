'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getAccessToken } from '@/lib/api';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    if (getAccessToken()) {
      router.replace('/dashboard');
    } else {
      router.replace('/login');
    }
  }, [router]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 text-slate-600">
      Загрузка…
    </div>
  );
}
