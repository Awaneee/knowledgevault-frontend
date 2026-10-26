import fs from 'node:fs';
import path from 'node:path';
import { chromium, type FullConfig } from '@playwright/test';
import { SEED_NOTES } from './fixtures/notes';
import { API, SESSION_FILE, STATE_FILE, login, type Session } from './tests/helpers';

async function api(pathname: string, init: RequestInit & { token?: string } = {}) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (init.token) headers.authorization = `Bearer ${init.token}`;
  // Retry once: uvicorn closes idle keep-alive sockets, which undici can race.
  const res = await fetch(`${API}${pathname}`, { ...init, headers }).catch(() =>
    fetch(`${API}${pathname}`, { ...init, headers }),
  );
  if (!res.ok) throw new Error(`${init.method ?? 'GET'} ${pathname} → ${res.status} ${await res.text()}`);
  return res.status === 204 ? null : res.json();
}

/**
 * Creates a fresh, already-organised account for the run: registers a user,
 * seeds notes, then waits for the AI worker to file them into categories so
 * the dashboard and category screens have real content.
 */
export default async function globalSetup(config: FullConfig) {
  const health = await fetch(`${API}/health`).catch(() => null);
  if (!health?.ok) throw new Error(`Backend not reachable at ${API} — start it with docker compose up`);

  const stamp = Date.now().toString(36);
  const session: Session = {
    username: `ananya_${stamp}`,
    email: `ananya.${stamp}@example.com`,
    password: 'vault-pass-123',
  };
  await api('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username: session.username, email: session.email, password: session.password }),
  });
  const { access_token: token } = await api('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: session.email, password: session.password }),
  });

  for (const content of SEED_NOTES) {
    await api('/notes/', { method: 'POST', token, body: JSON.stringify({ content }) });
  }

  // Wait (up to 4 min — a fresh worker downloads its embedding model first)
  // for the worker + LLM to organise the seeded notes.
  const deadline = Date.now() + 240_000;
  let organised = 0;
  while (Date.now() < deadline) {
    const notes = (await api('/notes/', { token })) as { organization_status?: string }[];
    organised = notes.filter((n) => n.organization_status === 'organized' || n.organization_status === 'failed').length;
    if (organised === notes.length) break;
    await new Promise((r) => setTimeout(r, 3000));
  }
  const cats = (await api('/intents/categories', { token })) as unknown[];
  console.log(`[setup] user ${session.email}: ${SEED_NOTES.length} notes, ${organised} organised, ${cats.length} categories`);

  fs.mkdirSync(path.dirname(SESSION_FILE), { recursive: true });
  fs.writeFileSync(SESSION_FILE, JSON.stringify(session, null, 2));

  // Sign in once through the real UI and keep the browser state (Flutter
  // stores the token in localStorage). The API allows only 5 logins a minute,
  // so specs reuse this state instead of signing in before every test.
  const { baseURL, launchOptions } = config.projects[0].use;
  const browser = await chromium.launch(launchOptions);
  const page = await browser.newPage({ baseURL, viewport: { width: 390, height: 844 } });
  await login(page, session);
  await page.context().storageState({ path: STATE_FILE });
  await browser.close();
}
