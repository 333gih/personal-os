import type { AuthMode, AuthState, LoginCredentials, RegisterCredentials } from './types';
import type { FashTokenResponse } from './fash-types';
import { AuthRequestError } from './auth-request-error';
import { fashAuthService } from './fash-auth-service';
import { isAccessTokenExpired, isAdminFromToken, userFromToken } from './jwt';
import {
  canUseStoredAccessToken,
  isRefreshTokenValid,
  shouldRefreshAccessToken,
} from './session-utils';
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

  async requestOtp(email: string): Promise<{ isNewUser: boolean }> {
    const result = await fashAuthService.requestOtp(email, 'commercial');
    return { isNewUser: result.is_new_user };
  }

  async verifyOtp(credentials: RegisterCredentials): Promise<AuthState> {
    const tokens = await fashAuthService.verifyOtp(
      credentials.email,
      credentials.otp,
      credentials.mode,
    );
    return this.finalizeAuth(tokens, credentials.mode);
  }

  async completeWebHandoff(payload: {
    access_token: string;
    refresh_token: string;
    expires_in: number;
    refresh_expires_in: number;
    mode: AuthMode;
  }): Promise<AuthState> {
    const tokens: FashTokenResponse = {
      access_token: payload.access_token,
      refresh_token: payload.refresh_token,
      token_type: 'bearer',
      expires_in: payload.expires_in,
      refresh_expires_in: payload.refresh_expires_in,
    };
    return this.finalizeAuth(tokens, payload.mode);
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

  /** Proactively refresh tokens when needed; returns whether a usable session exists. */
  async ensureSession(): Promise<boolean> {
    const auth = await storageService.getAuth();
    if (!auth) return false;

    if (!isRefreshTokenValid(auth)) {
      await storageService.setAuth(null);
      logger.info('Refresh token expired — session cleared');
      return false;
    }

    if (!shouldRefreshAccessToken(auth)) {
      return true;
    }

    const refreshed = await this.refreshTokens();
    if (refreshed) return true;

    const current = await storageService.getAuth();
    return current !== null && canUseStoredAccessToken(current);
  }

  async getValidAccessToken(): Promise<string | null> {
    const auth = await storageService.getAuth();
    if (!auth) return null;

    if (!isRefreshTokenValid(auth)) {
      await storageService.setAuth(null);
      return null;
    }

    if (!shouldRefreshAccessToken(auth)) {
      return auth.tokens.accessToken;
    }

    const refreshed = await this.refreshTokens();
    if (refreshed) {
      return refreshed.tokens.accessToken;
    }

    const current = await storageService.getAuth();
    if (current && canUseStoredAccessToken(current)) {
      logger.warn('Using stored access token while refresh is temporarily unavailable');
      return current.tokens.accessToken;
    }

    if (current && !isAccessTokenExpired(current.tokens.accessToken, 0)) {
      return current.tokens.accessToken;
    }

    return null;
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
    return this.ensureSession();
  }

  private async doRefresh(): Promise<AuthState | null> {
    const auth = await storageService.getAuth();
    if (!auth) return null;

    if (!isRefreshTokenValid(auth)) {
      await storageService.setAuth(null);
      return null;
    }

    try {
      const response = await fashAuthService.refresh(auth.tokens.refreshToken, auth.mode);
      const updated = this.buildAuthState(response, auth.mode);
      await storageService.setAuth(updated);
      logger.info('Access token refreshed', { email: updated.user.email });
      return updated;
    } catch (error) {
      if (error instanceof AuthRequestError && error.isAuthError) {
        logger.error('Refresh token rejected — logging out', error);
        await storageService.setAuth(null);
        return null;
      }

      logger.warn('Token refresh failed (session kept for retry)', error);
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
    const accessExpiresIn = Math.max(60, tokens.expires_in);
    const refreshExpiresIn = Math.max(3600, tokens.refresh_expires_in);

    return {
      mode,
      applicationId: getApplicationId(mode),
      tokens: {
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresAt: now + accessExpiresIn * 1000,
        refreshExpiresAt: now + refreshExpiresIn * 1000,
      },
      user: {
        ...user,
        isAdmin: isAdminFromToken(tokens.access_token),
      },
    };
  }
}

export const authService = new AuthService();
