import { decodeJwtPayload } from "./jwt";

function claimString(payload: Record<string, unknown>, key: string): string | null {
  const value = payload[key];
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

export function isAdminFromToken(token: string): boolean {
  const payload = decodeJwtPayload(token);
  if (!payload) return false;
  return payload.is_admin === true || payload.admin === true;
}

export function hasInternalAppAccess(token: string, applicationId: string): boolean {
  const payload = decodeJwtPayload(token);
  if (!payload) return false;

  const expected = applicationId.trim();
  const app = claimString(payload, "app") ?? claimString(payload, "application_id");
  if (app && (app === expected || app === applicationId)) {
    return true;
  }

  const groupIds = payload.group_ids;
  if (Array.isArray(groupIds)) {
    return groupIds.some((id) => typeof id === "string" && id.trim() === expected);
  }

  return false;
}
