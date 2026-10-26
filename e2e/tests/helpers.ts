import fs from 'node:fs';
import path from 'node:path';
import { expect, type Locator, type Page } from '@playwright/test';

export const API = process.env.API_URL ?? 'http://localhost:8000';
export const SESSION_FILE = path.resolve(__dirname, '../.auth/session.json');
/** Browser storage of the signed-in seeded user (written by global setup). */
export const STATE_FILE = path.resolve(__dirname, '../.auth/state.json');
export const SCREENSHOT_DIR = path.resolve(
  __dirname,
  process.env.SCREENSHOT_DIR ?? '../../screenshots',
);

export type Session = { username: string; email: string; password: string };

export function session(): Session {
  return JSON.parse(fs.readFileSync(SESSION_FILE, 'utf8'));
}

/**
 * Loads the app at [route] and switches on Flutter's semantics tree.
 *
 * Flutter web paints to a canvas; with semantics enabled it mirrors every
 * widget as a DOM node with ARIA roles/labels, which is what the locators
 * below query.
 */
export async function openApp(page: Page, route = '/') {
  const alreadyRunning = (await page.locator('flt-semantics').count()) > 0;
  await page.goto(`/#${route}`);
  // A hash-only navigation doesn't reload the app; semantics are still on.
  if (alreadyRunning) return;
  await page.locator('flt-semantics-placeholder').waitFor({ state: 'attached', timeout: 60_000 });
  await page.evaluate(() =>
    (document.querySelector('flt-semantics-placeholder') as HTMLElement | null)?.click(),
  );
  await page.locator('flt-semantics').first().waitFor({ state: 'attached' });
}

export const button = (page: Page, name: string | RegExp) =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

export const field = (page: Page, name: string | RegExp) =>
  page.getByRole('textbox', { name });

/**
 * Matches [value] in visible text or in an ARIA label. Flutter often exposes
 * a widget's text as its semantics node's aria-label, and merges multi-line
 * rich text into one node, so this matches substrings rather than whole nodes.
 */
export const text = (page: Page, value: string | RegExp) => {
  const re =
    typeof value === 'string'
      ? new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
      : value;
  return page.getByText(re).or(page.getByLabel(re)).first();
};

/** Focuses a Flutter text field and types like a user would. */
export async function typeInto(locator: Locator, value: string) {
  const page = locator.page();
  for (let attempt = 0; attempt < 3; attempt++) {
    await locator.click();
    await page.keyboard.press('ControlOrMeta+a');
    await page.keyboard.press('Backspace');
    await page.keyboard.type(value, { delay: 15 });
    // Flutter's web text input can drop keystrokes on a busy machine.
    if ((await locator.inputValue().catch(() => value)) === value) return;
  }
  throw new Error(`Could not type "${value}" into the field`);
}

/** Scrolls the Flutter canvas under the pointer. */
export async function scroll(page: Page, dy: number, at = { x: 195, y: 450 }) {
  await page.mouse.move(at.x, at.y);
  await page.mouse.wheel(0, dy);
  await page.waitForTimeout(600);
}

/** Lets animations settle, then saves a screenshot to ../screenshots. */
export async function shot(page: Page, name: string) {
  // Park the pointer so hover tooltips don't end up in the picture.
  await page.mouse.move(1, 1);
  await page.waitForTimeout(900);
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, `${name}.png`) });
}

export async function login(page: Page, s: Session = session()) {
  await openApp(page, '/login');
  await typeInto(field(page, 'Email'), s.email);
  await typeInto(field(page, 'Password'), s.password);
  await button(page, 'Sign In').click();
  await expect(button(page, 'Profile')).toBeVisible({ timeout: 30_000 });
}

/** Opens the app as the already signed-in seeded user (see STATE_FILE). */
export async function openHome(page: Page) {
  await openApp(page, '/');
  await expect(button(page, 'Profile')).toBeVisible({ timeout: 30_000 });
}

/** Taps a bottom-navigation tab by its label. */
export async function tab(page: Page, label: 'Home' | 'Categories' | 'Ask AI' | 'Chats' | 'Settings') {
  // "Ask AI" also exists as a button on the dashboard hero; the nav one is last.
  await button(page, label).last().click();
  await page.waitForTimeout(500);
}

export async function setTheme(page: Page, mode: 'Light' | 'Dark' | 'System') {
  await tab(page, 'Settings');
  await page.getByRole('button', { name: mode }).or(page.getByRole('radio', { name: mode })).first().click();
  await page.waitForTimeout(400);
}
