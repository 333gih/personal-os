export class AuthRequestError extends Error {
  constructor(
    message: string,
    public readonly status: number,
  ) {
    super(message);
    this.name = 'AuthRequestError';
  }

  get isAuthError(): boolean {
    return this.status === 401 || this.status === 403;
  }

  get isRetryable(): boolean {
    return !this.isAuthError && (this.status === 0 || this.status >= 500 || this.status === 429);
  }
}
