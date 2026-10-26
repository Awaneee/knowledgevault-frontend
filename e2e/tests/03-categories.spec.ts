import { expect, test } from '@playwright/test';
import { STATE_FILE, openHome, shot, tab, text } from './helpers';

test.describe('AI categories', () => {
  test.use({ storageState: STATE_FILE });
  test.beforeEach(async ({ page }) => openHome(page));

  test('categories grid and a folder of notes', async ({ page }) => {
    await tab(page, 'Categories');
    await expect(page.getByRole('button', { name: /\d+ notes?$/ }).first()).toBeVisible();
    await shot(page, '30-categories');
    // Open the first folder card.
    await page.getByRole('button', { name: /\d+ notes?$/ }).first().click();
    await expect(page.getByRole('button', { name: 'New note' })).toBeVisible();
    await page.waitForTimeout(1500);
    await shot(page, '31-category-notes');
  });
});
