import { expect, test } from '@playwright/test';
import { STATE_FILE, openHome, shot, text } from './helpers';

test.describe('Wide layout', () => {
  test.use({
    storageState: STATE_FILE,
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 1,
  });

  test('desktop shows a navigation rail', async ({ page }) => {
    await openHome(page);
    await expect(text(page, 'KnowledgeVault').first()).toBeVisible();
    await shot(page, '80-desktop-dashboard');
    // Flutter doesn't expose rail labels to the DOM; click the fixed rail rows.
    const railY = { Categories: 167, 'Ask AI': 211 } as const;
    const rail = (label: keyof typeof railY) => ({
      click: () => page.mouse.click(110, railY[label]),
    });
    await rail('Categories').click();
    await expect(page.getByRole('button', { name: /\d+ notes?$/ }).first()).toBeVisible();
    await shot(page, '81-desktop-categories');
    await rail('Ask AI').click();
    await expect(text(page, 'Ask KnowledgeVault')).toBeVisible();
    await shot(page, '82-desktop-ask');
  });
});
