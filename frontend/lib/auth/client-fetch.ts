"use client";

const REFRESH_PATH = "/api/auth/refresh";

export async function portalFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const doFetch = () =>
    fetch(input, {
      ...init,
      credentials: init?.credentials ?? "same-origin",
    });

  let res = await doFetch();
  if (res.status !== 401) {
    return res;
  }

  const refresh = await fetch(REFRESH_PATH, {
    method: "POST",
    credentials: "same-origin",
    headers: { Accept: "application/json" },
  });

  if (!refresh.ok) {
    return res;
  }

  return doFetch();
}
