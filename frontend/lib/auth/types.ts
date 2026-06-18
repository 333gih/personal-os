export type LoginRequest = {
  email: string;
  password: string;
  application_id: string;
  client_channel?: string;
};

export type SocialLoginRequest = {
  provider: string;
  provider_token: string;
  application_id: string;
  client_channel?: string;
};

export type OtpEmailRequest = {
  email: string;
  application_id: string;
  client_channel?: string;
};

export type OtpVerifyRequest = {
  email: string;
  application_id: string;
  otp: string;
  client_channel?: string;
};

export type RefreshRequest = {
  refresh_token: string;
  application_id: string;
};

export type LogoutRequest = {
  refresh_token: string;
  application_id: string;
};

export type TokenResponse = {
  access_token: string;
  refresh_token: string;
  token_type: "bearer";
  expires_in: number;
  refresh_expires_in: number;
  user?: {
    id: string;
    email: string;
    is_admin?: boolean;
    full_name?: string;
  };
};
