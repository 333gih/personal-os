import type { AuthMode, AuthState, LoginCredentials, RegisterCredentials } from './types';
import type { FashTokenResponse } from './fash-types';
import { fashAuthService } from './fash-auth-service';
import { isAccessTokenExpired, isAdminFromToken, userFromToken } from './jwt';
import { getApplicationId } from './auth-api-config';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

export class AuthService {
  private refreshPromise: Promise<AuthState | null> | null = null;

  async login(credentials: LoginCredentials): Promise<AuthState> {
    const tokens = await fashAuthService.login(
      credentials.email,
      credentials.password,
      credentials.mode,
    );
    return this.finalizeAuth(tokens, credentials.mode);
  }

  async register(credentials: RegisterCredentials): Promise<AuthState> {
    const tokens = await fashAuthService.register(
      credentials.email,
      credentials.password,
      credentials.name,
      credentials.mode,
    );
    return this.finalizeAuth(tokens, credentials.mode);
  }

  async logout(): Promise<void> {
    const auth = await storageService.getAuth();
    if (auth) {
      await fashAuthService.logout(auth.tokens.refreshToken, auth.mode);
    }
    await storageService.setAuth(null);
    logger.info('User logged out');
  }

  async getAuthState(): Promise<AuthState | null> {
    return storageService.getAuth();
  }

  async getValidAccessToken(): Promise<string | null> {
    const auth = await storageService.getAuth();
    if (!auth) return null;

    if (!isAccessTokenExpired(auth.tokens.accessToken)) {
      return auth.tokens.accessToken;
    }

    const refreshed = await this.refreshTokens();
    return refreshed?.tokens.accessToken ?? null;
  }

  async refreshTokens(): Promise<AuthState | null> {
    if (this.refreshPromise) return this.refreshPromise;

    this.refreshPromise = this.doRefresh();
    try {
      return await this.refreshPromise;
    } finally {
      this.refreshPromise = null;
    }
  }

  async isAuthenticated(): Promise<boolean> {
    const token = await this.getValidAccessToken();
    return token !== null;
  }

  private async doRefresh(): Promise<AuthState | null> {
    const auth = await storageService.getAuth();
    if (!auth) return null;

    try {
      const response = await fashAuthService.refresh(auth.tokens.refreshToken, auth.mode);
      const updated = this.buildAuthState(response, auth.mode);
      await storageService.setAuth(updated);
      return updated;
    } catch (error) {
      logger.error('Token refresh failed, logging out', error);
      await storageService.setAuth(null);
      return null;
    }
  }

  private async finalizeAuth(tokens: FashTokenResponse, mode: AuthMode): Promise<AuthState> {
    const authState = this.buildAuthState(tokens, mode);

    if (mode === 'internal' && !authState.user.isAdmin) {
      throw new AuthError('Access denied. Internal login requires an admin account.');
    }

    await storageService.setAuth(authState);
    logger.info(`User authenticated (${mode})`, { email: authState.user.email });
    return authState;
  }

  private buildAuthState(tokens: FashTokenResponse, mode: AuthMode): AuthState {
    const user = userFromToken(tokens.access_token);
    const now = Date.now();

    return {
      mode,
      applicationId: getApplicationId(mode),
      tokens: {
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresAt: now + tokens.expires_in * 1000,
        refreshExpiresAt: now + tokens.refresh_expires_in * 1000,
      },
      user: {
        ...user,
        isAdmin: isAdminFromToken(tokens.access_token),
      },
    };
  }
}

export const authService = new AuthService();
