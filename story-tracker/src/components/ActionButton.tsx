import type { ButtonHTMLAttributes, ReactNode } from 'react';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'icon';

type ActionButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  loading?: boolean;
  success?: boolean;
  loadingLabel?: string;
  successLabel?: string;
  block?: boolean;
  children: ReactNode;
};

export function ActionButton({
  variant = 'primary',
  loading = false,
  success = false,
  loadingLabel,
  successLabel = 'Done',
  block = false,
  disabled,
  className = '',
  children,
  ...rest
}: ActionButtonProps) {
  const isDisabled = disabled || loading || success;
  const variantClass =
    variant === 'icon' ? 'btn--icon'
    : success ? 'btn--success'
    : `btn--${variant}`;

  return (
    <button
      type="button"
      className={['btn', variantClass, block ? 'btn--block' : '', className].filter(Boolean).join(' ')}
      disabled={isDisabled}
      aria-busy={loading}
      {...rest}
    >
      {loading ?
        <>
          <span className="btn__spinner" aria-hidden />
          <span>{loadingLabel ?? children}</span>
        </>
      : success ?
        <>
          <span className="btn__check" aria-hidden>
            ✓
          </span>
          <span>{successLabel}</span>
        </>
      : children}
    </button>
  );
}
