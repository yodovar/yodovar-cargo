const DEFAULT_API_BASE = 'http://127.0.0.1:51580';

function trimTrailingSlash(value: string): string {
  return value.replace(/\/$/, '');
}

/**
 * Возвращает базовый URL API.
 * Если в конфиге указан localhost/127.0.0.1, а сайт открыт по LAN IP (с телефона),
 * то автоматически подменяет хост API на текущий хост страницы.
 */
export function getApiBase(): string {
  const configured =
    (typeof process !== 'undefined' && process.env.NEXT_PUBLIC_API_BASE) ||
    DEFAULT_API_BASE;
  const clean = trimTrailingSlash(configured);

  if (typeof window === 'undefined') return clean;

  try {
    const parsed = new URL(clean);
    const isLoopbackHost =
      parsed.hostname === '127.0.0.1' || parsed.hostname === 'localhost';
    const pageHost = window.location.hostname;
    const pageIsLoopback = pageHost === '127.0.0.1' || pageHost === 'localhost';

    if (isLoopbackHost && !pageIsLoopback) {
      parsed.hostname = pageHost;
      return trimTrailingSlash(parsed.toString());
    }
    return clean;
  } catch {
    return clean;
  }
}
