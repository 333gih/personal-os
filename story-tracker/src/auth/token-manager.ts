import { authService } from './auth-service';
import { ApiError } from '../services/api-client';

export class TokenManager {
  getAccessToken(): Promise<string | null> {
    return authService.getValidAccessToken();
  }

  async ensureValidToken(): Promise<string | null> {
    return authService.getValidAccessToken();
  }

  /** Ensures session is fresh, then returns a non-empty Bearer token or throws. */
  async requireAccessToken(): Promise<string> {
    await authService.ensureSession();
    const token = (await authService.getValidAccessToken())?.trim();
    if (!token) {
      throw new ApiError('Not authenticated. Sign in via Personal OS.', 401);
    }
    return token;
  }
}

export const tokenManager = new TokenManager();
