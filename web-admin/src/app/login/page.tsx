'use client';

import Image from 'next/image';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { apiFetch, setTokens } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function login(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const data = await apiFetch<{ accessToken: string; refreshToken: string }>(
        '/auth/staff-login',
        {
        method: 'POST',
        body: JSON.stringify({ name: name.trim(), password }),
      },
      );
      setTokens(data.accessToken, data.refreshToken);

      const me = await apiFetch<{ role: string; name: string }>('/me');
      if (!['admin', 'worker_cn', 'worker_tj'].includes(me.role)) {
        setTokens('', '');
        throw new Error('Доступ только для админа и сотрудников');
      }
      router.replace('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 px-4">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="mb-4 flex justify-center">
          <Image src="/logo/logo.png" alt="Insof Cargo" width={180} height={90} priority />
        </div>
        <h1 className="text-xl font-bold text-slate-900">Вход в админку</h1>
        <p className="mt-1 text-sm text-slate-500">
          Для сотрудников: вход по имени и паролю
        </p>

        {error && (
          <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
            {error}
          </div>
        )}

        <form onSubmit={login} className="mt-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700">
              Имя
            </label>
            <input
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Admin"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700">
              Пароль
            </label>
            <input
              type="password"
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-orange-600 py-2.5 font-medium text-white hover:bg-orange-700 disabled:opacity-50"
          >
            {loading ? 'Вход…' : 'Войти'}
          </button>
        </form>
      </div>
    </div>
  );
}
