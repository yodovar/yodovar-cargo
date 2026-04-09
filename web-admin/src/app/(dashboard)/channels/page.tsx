'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiFetch } from '@/lib/api';

type AdminChannelPost = {
  id: string;
  body: string;
  createdAt: string;
  updatedAt: string;
  views: number;
  author: {
    id: string;
    name: string;
    role: string;
  };
  reactions: Array<{
    emoji: string;
    count: number;
  }>;
};

export default function ChannelsPage() {
  const [items, setItems] = useState<AdminChannelPost[]>([]);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [posting, setPosting] = useState(false);
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const res = await apiFetch<{ items: AdminChannelPost[] }>('/admin/channel-posts?take=100');
      setItems(res.items);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function publish() {
    const body = message.trim();
    if (!body) return;
    setPosting(true);
    setErr('');
    try {
      await apiFetch('/admin/channel-posts', {
        method: 'POST',
        body: JSON.stringify({ body }),
      });
      setMessage('');
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка публикации');
    } finally {
      setPosting(false);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Канал</h1>
      <p className="mt-1 text-slate-600">
        Публикации для клиентов с метриками просмотров и реакций
      </p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      <div className="mt-5 rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="text-sm font-semibold text-slate-800">Новое сообщение канала</h2>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Напишите сообщение клиентам..."
          className="mt-2 min-h-[110px] w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          maxLength={4000}
        />
        <div className="mt-2 flex items-center justify-between">
          <span className="text-xs text-slate-500">{message.trim().length}/4000</span>
          <button
            type="button"
            onClick={() => void publish()}
            disabled={posting || message.trim().length === 0}
            className="rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700 disabled:opacity-50"
          >
            {posting ? 'Публикация...' : 'Опубликовать'}
          </button>
        </div>
      </div>

      <div className="mt-6 space-y-3">
        {loading ? (
          <div className="rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-500">
            Загрузка...
          </div>
        ) : items.length === 0 ? (
          <div className="rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-500">
            Сообщений пока нет
          </div>
        ) : (
          items.map((p) => <PostCard key={p.id} post={p} />)
        )}
      </div>
    </div>
  );
}

function PostCard({ post }: { post: AdminChannelPost }) {
  const reactions = useMemo(() => {
    if (!post.reactions || post.reactions.length === 0) return '—';
    return post.reactions.map((r) => `${r.emoji} ${r.count}`).join('  ');
  }, [post.reactions]);
  return (
    <article className="rounded-xl border border-slate-200 bg-white p-4">
      <div className="mb-2 flex items-center justify-between text-xs text-slate-500">
        <span>
          Автор: {post.author?.name || 'Админ'} ({post.author?.role || 'admin'})
        </span>
        <span>{formatDate(post.createdAt)}</span>
      </div>
      <p className="whitespace-pre-wrap text-[15px] leading-6 text-slate-800">{post.body}</p>
      <div className="mt-3 flex flex-wrap gap-4 text-sm text-slate-600">
        <span>Просмотры: {post.views}</span>
        <span>Реакции: {reactions}</span>
      </div>
    </article>
  );
}

function formatDate(value: string) {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}
