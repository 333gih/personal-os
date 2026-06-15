export type LoginRequest = {
  email: string;
  password: string;
  application_id: string;
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
};
