export type AuthMode = 'internal' | 'commercial';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
  refreshExpiresAt: number;
}

export interface AuthUser {
  id: string;
  email: string;
  name?: string;
  isAdmin: boolean;
}

export interface AuthState {
  mode: AuthMode;
  applicationId: string;
  tokens: AuthTokens;
  user: AuthUser;
}

export interface LoginCredentials {
  email: string;
  password: string;
  mode: AuthMode;
}

export interface RegisterCredentials {
  email: string;
  password: string;
  name: string;
  mode: 'commercial';
}
