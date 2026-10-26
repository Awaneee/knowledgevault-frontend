import path from 'node:path';
import { expect, test } from '@playwright/test';
import { STATE_FILE, button, openHome, session, setTheme, shot, tab, text } from './helpers';

test.describe('Settings and profile', () => {
  test.use({ storageState: STATE_FILE });
  test.beforeEach(async ({ page }) => openHome(page));

  test('settings shows server status and organise action', async ({ page }) => {
    await tab(page, 'Settings');
    await expect(text(page, 'Online')).toBeVisible();
    await shot(page, '60-settings');
    await button(page, 'Run').click();
    await expect(text(page, 'Organise notes?')).toBeVisible();
    await shot(page, '61-settings-organise-dialog');
    await button(page, 'Cancel').click();
  });

  test('profile: edit username and upload an avatar', async ({ page }) => {
    await button(page, 'Profile').click();
    await expect(text(page, session().email).first()).toBeVisible();
    await shot(page, '62-profile');

    await button(page, 'Edit Username').click();
    await expect(text(page, 'Edit username')).toBeVisible();
    await shot(page, '63-profile-edit-username');
    await button(page, 'Cancel').click();

    await button(page, /Change picture/).click();
    const chooser = page.waitForEvent('filechooser');
    await text(page, 'Choose picture').click();
    await (await chooser).setFiles(path.resolve(__dirname, '../../assets/icon/icon.png'));
    await page.waitForTimeout(2500);
    await shot(page, '64-profile-avatar');
  });

  test('log out returns to sign-in', async ({ page }) => {
    await tab(page, 'Settings');
    await text(page, 'Log out').click();
    await expect(button(page, 'Sign In')).toBeVisible();
  });
});

test.describe('Dark theme', () => {
  test.use({ storageState: STATE_FILE });

  test('every main screen in dark mode', async ({ page }) => {
    await openHome(page);
    await setTheme(page, 'Dark');
    await shot(page, '70-dark-settings');
    await tab(page, 'Home');
    await shot(page, '71-dark-dashboard');
    await tab(page, 'Categories');
    await shot(page, '72-dark-categories');
    await tab(page, 'Ask AI');
    await shot(page, '73-dark-ask');
    await tab(page, 'Chats');
    await shot(page, '74-dark-chats');
    await tab(page, 'Home');
    await button(page, /Total Notes$/).click();
    await shot(page, '75-dark-notes-list');
    await text(page, /Reference: Transformers use scaled/).click();
    await shot(page, '76-dark-note-detail');
    // Sign-in screen in dark mode (theme choice persists across logout).
    await page.goBack();
    await page.goBack();
    await tab(page, 'Settings');
    await text(page, 'Log out').click();
    await expect(button(page, 'Sign In')).toBeVisible();
    await shot(page, '77-dark-login');
  });
});
