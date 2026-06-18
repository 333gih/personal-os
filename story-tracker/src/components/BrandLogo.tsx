import browser from 'webextension-polyfill';

const ICON_48 = 'icons/icon-48.png';

type BrandLogoProps = {
  size?: number;
  className?: string;
};

export function BrandLogo({ size = 40, className }: BrandLogoProps) {
  return (
    <img
      src={browser.runtime.getURL(ICON_48)}
      alt=""
      width={size}
      height={size}
      className={className}
      aria-hidden
      draggable={false}
    />
  );
}
