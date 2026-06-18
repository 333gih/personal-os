export type FashLoginRequest = {
  email: string;
  password: string;
  application_id: string;
  client_channel?: string;
};

export type FashRefreshRequest = {
  refresh_token: string;
  application_id: string;
};

export type FashLogoutRequest = {
  refresh_token: string;
  application_id: string;
};

export type FashOtpEmailRequest = {
  email: string;
  application_id: string;
  client_channel?: string;
};

export type FashOtpVerifyRequest = {
  email: string;
  otp: string;
  application_id: string;
  client_channel?: string;
};

export type FashTokenResponse = {
  access_token: string;
  refresh_token: string;
  token_type: 'bearer';
  expires_in: number;
  refresh_expires_in: number;
  is_new_user?: boolean;
};

export type FashErrorBody = {
  message?: string;
  error?: string;
  detail?: string;
  [key: string]: unknown;
};
