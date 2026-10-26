import { expect, test } from '@playwright/test';
import { STATE_FILE, button, field, openHome, shot, tab, text, typeInto } from './helpers';

test.describe('Conversations', () => {
  test.use({ storageState: STATE_FILE });
  test.beforeEach(async ({ page }) => openHome(page));

  test('start a chat and get a reply', async ({ page }) => {
    await tab(page, 'Chats');
    await expect(text(page, 'Conversations')).toBeVisible();
    await shot(page, '50-chats-empty');

    await button(page, 'New chat').click();
    await expect(text(page, 'conversation')).toBeVisible();
    await shot(page, '51-chat-new');

    await typeInto(field(page, /Continue the conversation/), 'When is the hackathon and what is the theme?');
    await button(page, 'Send').click();
    // The reply's wording depends on the LLM (or the backend's no-LLM
    // fallback); the input re-enables once it has arrived.
    await expect(page.getByRole('textbox', { name: /Continue the conversation/ })).toBeEnabled({ timeout: 90_000 });
    await shot(page, '52-chat-reply');

    await page.goBack();
    // Question + assistant reply were both saved to the session.
    await expect(text(page, /2 messages/)).toBeVisible();
    await shot(page, '53-chats-list');
  });
});
