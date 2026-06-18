import { authService } from './auth-service';

export class TokenManager {
  getAccessToken(): Promise<string | null> {
    return authService.getValidAccessToken();
  }

  async ensureValidToken(): Promise<string | null> {
    return authService.getValidAccessToken();
  }
}

export const tokenManager = new TokenManager();
