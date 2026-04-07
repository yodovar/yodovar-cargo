export type AuthRole = 'client' | 'worker_cn' | 'worker_tj' | 'admin';

export type JwtAccessPayload = {
  sub: string;
  role: AuthRole;
};

export type JwtRefreshPayload = {
  sub: string;
  role: AuthRole;
  typ: 'refresh';
};

export type RequestUser = {
  id: string;
  role: AuthRole;
};
