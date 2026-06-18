export const AUTH_CLIENT_CHANNELS = {
  STORY_TRACKER_EXTENSION: 'story_tracker_extension',
} as const;

export function clientChannelForMode(): string {
  return AUTH_CLIENT_CHANNELS.STORY_TRACKER_EXTENSION;
}
