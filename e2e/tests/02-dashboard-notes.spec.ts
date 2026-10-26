import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';
import { expect, test } from '@playwright/test';
import { UPLOAD_TEXT } from '../fixtures/notes';
import { STATE_FILE, button, openHome, scroll, shot, text, typeInto } from './helpers';

test.describe('Dashboard and notes', () => {
  test.use({ storageState: STATE_FILE });
  test.beforeEach(async ({ page }) => openHome(page));

  test('dashboard shows greeting, stats, categories and recent notes', async ({ page }) => {
    await expect(text(page, /Good (morning|afternoon|evening),/)).toBeVisible();
    await expect(button(page, /^8 Total Notes$/)).toBeVisible();
    await shot(page, '10-dashboard');
    await scroll(page, 520);
    await expect(text(page, 'Recent notes')).toBeVisible();
    await shot(page, '11-dashboard-recent-notes');
    await scroll(page, 700);
    await shot(page, '12-dashboard-categories');
  });

  test('create a note from the editor', async ({ page }) => {
    await button(page, 'New Note').click();
    await expect(button(page, 'Import file')).toBeVisible();
    const editor = page.getByRole('textbox').first();
    await typeInto(
      editor,
      'Weekend reading: finish chapter 3 of Designing Data-Intensive Applications and take notes on replication lag.',
    );
    await shot(page, '13-create-note');
    await button(page, 'Save').click();
    await expect(text(page, /Weekend reading: finish chapter 3/)).toBeVisible();
    await expect(text(page, 'Attachments')).toBeVisible();
    await shot(page, '14-note-detail');
  });

  test('notes list with category filters', async ({ page }) => {
    await button(page, /Total Notes$/).click();
    await expect(text(page, 'My Notes')).toBeVisible();
    await expect(page.getByRole('button', { name: 'All' }).or(page.getByRole('checkbox', { name: 'All' })).first()).toBeVisible();
    await shot(page, '15-notes-list');
  });

  test('change a note category and create a new one', async ({ page }) => {
    await button(page, /Total Notes$/).click();
    await text(page, /Study plan for the compilers exam/).click();
    await expect(text(page, 'Category')).toBeVisible();
    await text(page, 'Category').click();
    await expect(text(page, 'Choose category')).toBeVisible();
    await shot(page, '16-category-picker');
    await typeInto(page.getByRole('textbox', { name: /Search or type a new name/ }), 'Exam prep');
    await button(page, 'Create "Exam prep"').click();
    await expect(text(page, 'Category updated')).toBeVisible();
    await expect(text(page, 'Exam prep')).toBeVisible();
    await shot(page, '17-category-updated');
  });

  test('upload an attachment to a note', async ({ page }) => {
    const file = path.join(os.tmpdir(), 'lexical-analysis-notes.txt');
    fs.writeFileSync(file, UPLOAD_TEXT);
    await button(page, /Total Notes$/).click();
    await text(page, /Reference: Transformers use scaled/).click();
    await scroll(page, 600);
    const chooser = page.waitForEvent('filechooser');
    await button(page, 'Add attachment').click();
    await (await chooser).setFiles(file);
    await expect(text(page, 'lexical-analysis-notes.txt')).toBeVisible();
    await shot(page, '18-note-attachment');
  });

  test('import a file as a new note', async ({ page }) => {
    const file = path.join(os.tmpdir(), 'lecture-01-lexical-analysis.txt');
    fs.writeFileSync(file, UPLOAD_TEXT);
    await button(page, 'New Note').click();
    const chooser = page.waitForEvent('filechooser');
    await button(page, 'Import file').click();
    await (await chooser).setFiles(file);
    await expect(text(page, /Lecture 1/)).toBeVisible({ timeout: 30_000 });
    await shot(page, '19-imported-note');
  });

  test('delete a note', async ({ page }) => {
    await button(page, /Total Notes$/).click();
    // Newest first: the note imported by the previous test is at the top.
    await text(page, /Lecture 1/).click();
    await button(page, 'More options').click();
    await page.getByRole('menuitem', { name: 'Delete note' }).click();
    await expect(text(page, 'Delete note?')).toBeVisible();
    await shot(page, '20-delete-note-confirm');
    await button(page, 'Delete').click();
    await expect(text(page, 'My Notes')).toBeVisible();
    await expect(page.getByText(/Lecture 1/)).toHaveCount(0);
  });
});
