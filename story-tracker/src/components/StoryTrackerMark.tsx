import { useId } from 'react';

type StoryTrackerMarkProps = {
  size?: number;
  className?: string;
  title?: string;
};

export function StoryTrackerMark({ size = 40, className, title }: StoryTrackerMarkProps) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512"
      width={size}
      height={size}
      className={className}
      role="img"
      aria-label={title ?? 'Story Tracker'}
    >
      <rect width="512" height="512" rx="96" fill="#1f1b18" />
      <rect x="20" y="20" width="472" height="472" rx="84" fill="none" stroke="#3a342f" strokeWidth="4" />
      <g fill="#f3ece5">
        <path d="M244 154h24v204h-24z" />
        <path d="M244 170 164 206v118c0 14 10 24 24 28l56 14V170z" />
        <path d="M268 170l80 36v118c0 14-10 24-24 28l-56 14V170z" />
      </g>
      <path d="M300 178h28v54l-14-10-14 10V178z" fill="#ff4b64" />
    </svg>
  );
}
