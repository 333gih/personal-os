/**
 * Ensure App Store Connect app record exists for Story Tracker.
 * Usage: node scripts/asc-ensure-app.mjs
 */
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const envPath = path.join(root, 'secrets', 'ios-release.env');

function readEnv(file) {
  const map = {};
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i < 1) continue;
    map[t.slice(0, i).trim()] = t.slice(i + 1).trim();
  }
  return map;
}

function b64url(input) {
  return Buffer.from(input).toString('base64url');
}

function makeJwt(issuerId, keyId, p8) {
  const enc = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
  const header = enc({ alg: 'ES256', kid: keyId, typ: 'JWT' });
  const now = Math.floor(Date.now() / 1000);
  const payload = enc({ iss: issuerId, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' });
  const signingInput = `${header}.${payload}`;
  const sig = crypto.sign('sha256', Buffer.from(signingInput), {
    key: p8,
    format: 'pem',
    dsaEncoding: 'ieee-p1363',
  });
  return `${signingInput}.${sig.toString('base64url')}`;
}

async function asc(pathname, { method = 'GET', body, token }) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${pathname}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = { raw: text }; }
  if (!res.ok) {
    const err = new Error(`ASC ${method} ${pathname} -> ${res.status}: ${text}`);
    err.status = res.status;
    err.json = json;
    throw err;
  }
  return json;
}

const env = readEnv(envPath);
const issuerId = env.APP_STORE_CONNECT_ISSUER_ID;
const keyId = env.APP_STORE_CONNECT_API_KEY_ID;
const p8Path = path.join(root, env.APP_STORE_CONNECT_API_PRIVATE_KEY_PATH);
const bundleId = 'com.personalos.story-tracker';
const p8 = fs.readFileSync(p8Path, 'utf8');
const token = makeJwt(issuerId, keyId, p8);

const existing = await asc(
  `/v1/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`,
  { token },
);

if (existing.data?.length) {
  const app = existing.data[0];
  console.log(`App exists: ${app.attributes.name} (${app.attributes.bundleId}) id=${app.id}`);
  process.exit(0);
}

console.log('Creating App Store Connect app record...');
const bundle = await asc(
  `/v1/bundleIds?filter[identifier]=${encodeURIComponent(bundleId)}&limit=1`,
  { token },
);
if (!bundle.data?.length) {
  console.error(`Bundle ID not found in ASC: ${bundleId}`);
  process.exit(1);
}
const bundleResourceId = bundle.data[0].id;

try {
  const created = await asc('/v1/apps', {
    method: 'POST',
    token,
    body: {
      data: {
        type: 'apps',
        attributes: {
          name: 'Story Tracker',
          bundleId,
          sku: 'story-tracker-ios-001',
          primaryLocale: 'en-US',
        },
        relationships: {
          bundleId: {
            data: { type: 'bundleIds', id: bundleResourceId },
          },
        },
      },
    },
  });
  console.log(`Created app: ${created.data.attributes.name} id=${created.data.id}`);
} catch (e) {
  if (e.status === 409) {
    console.log('App already exists (409) — OK');
    process.exit(0);
  }
  throw e;
}
