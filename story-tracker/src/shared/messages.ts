export const MESSAGE_TYPES = {
  READING_UPDATE: 'READING_UPDATE',
  MANUAL_SAVE: 'MANUAL_SAVE',
  SYNC_NOW: 'SYNC_NOW',
  GET_STATE: 'GET_STATE',
  LOGIN: 'LOGIN',
  REQUEST_OTP: 'REQUEST_OTP',
  VERIFY_OTP: 'VERIFY_OTP',
  LOGOUT: 'LOGOUT',
  GET_AUTH_STATE: 'GET_AUTH_STATE',
  GET_SYNC_STATUS: 'GET_SYNC_STATUS',
  GET_READING_HISTORY: 'GET_READING_HISTORY',
  GET_CURRENT_READING: 'GET_CURRENT_READING',
  SETTINGS_UPDATED: 'SETTINGS_UPDATED',
  CHAPTER_CHANGED: 'CHAPTER_CHANGED',
} as const;

export type MessageType = (typeof MESSAGE_TYPES)[keyof typeof MESSAGE_TYPES];

export interface ExtensionMessage<T = unknown> {
  type: MessageType;
  payload?: T;
}

export interface MessageResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}
