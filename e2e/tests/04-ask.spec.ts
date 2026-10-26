import { expect, test } from '@playwright/test';
import { STATE_FILE, button, field, openHome, shot, tab, text, typeInto } from './helpers';

test.describe('Ask AI', () => {
  test.use({ storageState: STATE_FILE });
  test.beforeEach(async ({ page }) => openHome(page));

  test('streams an answer with cited sources', async ({ page }) => {
    await tab(page, 'Ask AI');
    await expect(text(page, 'Ask KnowledgeVault')).toBeVisible();
    await shot(page, '40-ask-empty');

    await typeInto(field(page, /Ask a question about your notes/), 'What did Sid and I agree to ship first?');
    await button(page, 'Send').click();
    await expect(text(page, 'Answer')).toBeVisible();
    await expect(button(page, 'Copy')).toBeVisible({ timeout: 90_000 });
    await shot(page, '41-ask-answer');

    const source = page.getByRole('button', { name: /^\[\d+\]/ }).first();
    if (await source.isVisible()) {
      await source.click();
      await expect(button(page, 'Go to note')).toBeVisible();
      await shot(page, '42-ask-citation');
    }
  });
});
