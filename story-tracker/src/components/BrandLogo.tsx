import { StoryTrackerMark } from './StoryTrackerMark';

type BrandLogoProps = {
  size?: number;
  className?: string;
};

export function BrandLogo({ size = 40, className }: BrandLogoProps) {
  return (
    <div
      className={['brand-logo', className].filter(Boolean).join(' ')}
      style={{ width: size, height: size }}
    >
      <StoryTrackerMark size={size} className="brand-logo__mark" />
    </div>
  );
}
