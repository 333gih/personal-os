export const AUTH_CLIENT_CHANNELS = {
  PERSONAL_OS_WEB_INTERNAL: "personal_os_web_internal",
  PERSONAL_OS_WEB_COMMERCIAL: "personal_os_web_commercial",
  STORY_TRACKER_EXTENSION: "story_tracker_extension",
  FASH_IOS_APP: "fash_ios_app",
  FASH_ANDROID_APP: "fash_android_app",
} as const;

export type AuthClientChannel =
  (typeof AUTH_CLIENT_CHANNELS)[keyof typeof AUTH_CLIENT_CHANNELS];

export type AuthMode = "internal" | "commercial";
