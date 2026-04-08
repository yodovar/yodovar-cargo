import { getApiBase } from './config';

function baseUrl() {
  return getApiBase();
}

export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('accessToken');
}

export function setTokens(access: string, refresh: string) {
  localStorage.setItem('accessToken', access);
  localStorage.setItem('refreshToken', refresh);
}

export function clearTokens() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
}

export async function apiFetch<T = unknown>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const requestUrl = `${baseUrl()}${path.startsWith('/') ? path : `/${path}`}`;
  const headers = new Headers(init.headers);
  if (!headers.has('Content-Type') && init.body && !(init.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }
  const token = getAccessToken();
  if (token) headers.set('Authorization', `Bearer ${token}`);

  async function doRequest(requestHeaders: Headers) {
    try {
      return await fetch(requestUrl, {
        ...init,
        headers: requestHeaders,
      });
    } catch {
      throw new Error(
        'Не удалось подключиться к API. Проверьте, что backend запущен и доступен по сети.',
      );
    }
  }

  let res: Response;
  res = await doRequest(headers);

  if (res.status === 401) {
    const isRefreshCall = path === '/auth/refresh' || path.endsWith('/auth/refresh');
    if (!isRefreshCall) {
      const refreshed = await refreshSession();
      if (refreshed) {
        const retriedHeaders = new Headers(init.headers);
        if (
          !retriedHeaders.has('Content-Type') &&
          init.body &&
          !(init.body instanceof FormData)
        ) {
          retriedHeaders.set('Content-Type', 'application/json');
        }
        const nextToken = getAccessToken();
        if (nextToken) retriedHeaders.set('Authorization', `Bearer ${nextToken}`);
        res = await doRequest(retriedHeaders);
      }
    }
  }

  if (res.status === 401) {
    clearTokens();
    if (typeof window !== 'undefined') window.location.href = '/login';
    throw new Error('Сессия истекла. Войдите снова.');
  }

  const text = await res.text();
  if (!res.ok) {
    let msg = text;
    try {
      const j = JSON.parse(text) as { message?: string | string[] };
      if (typeof j.message === 'string') msg = j.message;
      else if (Array.isArray(j.message)) msg = j.message.join(', ');
    } catch {
      /* ignore */
    }
    throw new Error(msg || `Ошибка ${res.status}`);
  }
  if (!text) return {} as T;
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as unknown as T;
  }
}

export async function refreshSession(): Promise<boolean> {
  if (typeof window === 'undefined') return false;
  const refresh = localStorage.getItem('refreshToken');
  if (!refresh) return false;
  try {
    const res = await fetch(`${baseUrl()}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refresh }),
    });
    if (!res.ok) return false;
    const data = (await res.json()) as {
      accessToken: string;
      refreshToken: string;
    };
    setTokens(data.accessToken, data.refreshToken);
    return true;
  } catch {
    return false;
  }
}
