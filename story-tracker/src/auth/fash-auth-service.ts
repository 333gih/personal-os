import type {
  FashLoginRequest,
  FashLogoutRequest,
  FashOtpEmailRequest,
  FashOtpVerifyRequest,
  FashTokenResponse,
} from './fash-types';
import { getApplicationId } from './auth-api-config';
import { postAuthJson } from './auth-http';
import { clientChannelForMode } from './channels';
import type { AuthMode } from './types';
import { lockedRefresh } from './locked-refresh';

export class FashAuthService {
  async login(email: string, password: string, mode: AuthMode): Promise<FashTokenResponse> {
    const body: FashLoginRequest = {
      email: email.trim(),
      password,
      application_id: getApplicationId(mode),
      client_channel: clientChannelForMode(),
    };
    return postAuthJson<FashTokenResponse>('/api/v1/auth/login', body);
  }

  async requestOtp(email: string, mode: AuthMode): Promise<{ is_new_user: boolean }> {
    const body: FashOtpEmailRequest = {
      email: email.trim(),
      application_id: getApplicationId(mode),
      client_channel: clientChannelForMode(),
    };
    const result = await postAuthJson<{ ok?: boolean; is_new_user?: boolean }>(
      '/api/v1/auth/otp/request',
      body,
    );
    return { is_new_user: result.is_new_user ?? false };
  }

  async verifyOtp(email: string, otp: string, mode: AuthMode): Promise<FashTokenResponse> {
    const body: FashOtpVerifyRequest = {
      email: email.trim(),
      otp: otp.trim(),
      application_id: getApplicationId(mode),
      client_channel: clientChannelForMode(),
    };
    return postAuthJson<FashTokenResponse>('/api/v1/auth/otp/verify', body);
  }

  async refresh(refreshToken: string, mode: AuthMode): Promise<FashTokenResponse> {
    return lockedRefresh(refreshToken, mode);
  }

  async logout(refreshToken: string, mode: AuthMode): Promise<void> {
    const body: FashLogoutRequest = {
      refresh_token: refreshToken,
      application_id: getApplicationId(mode),
    };
    try {
      await postAuthJson<void>('/api/v1/auth/logout', body);
    } catch {
      // Best-effort logout upstream; local session is always cleared.
    }
  }
}

export const fashAuthService = new FashAuthService();
