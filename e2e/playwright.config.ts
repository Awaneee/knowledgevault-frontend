import path from 'node:path';
import { defineConfig } from '@playwright/test';

/**
 * End-to-end tests for the Flutter web build.
 *
 * Prerequisites:
 *   1. Backend running on http://localhost:8000 (docker compose up).
 *   2. A web build: `flutter build web --release` (output in ../build/web).
 *
 * The suite serves ../build/web itself, signs up a fresh user, seeds notes
 * through the API and walks every feature, saving screenshots to
 * ../screenshots.
 *
 * If Chromium cannot find system libraries (no root to apt install), set
 * PW_LIB_DIR to a folder holding them; it is prepended to LD_LIBRARY_PATH.
 */
const libDir = process.env.PW_LIB_DIR;

export default defineConfig({
  testDir: './tests',
  globalSetup: './global-setup.ts',
  // Tests share one backend user and build on each other's data.
  fullyParallel: false,
  workers: 1,
  timeout: 180_000,
  expect: { timeout: 20_000 },
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'report' }]],
  outputDir: 'test-results',
  use: {
    baseURL: process.env.APP_URL ?? 'http://127.0.0.1:5555',
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    colorScheme: 'light',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    launchOptions: libDir
      ? {
          env: {
            ...process.env,
            LD_LIBRARY_PATH: [libDir, process.env.LD_LIBRARY_PATH]
              .filter(Boolean)
              .join(':'),
          },
        }
      : {},
  },
  webServer: {
    command: `python3 -m http.server 5555 --bind 127.0.0.1 --directory ${path.resolve(__dirname, '../build/web')}`,
    url: 'http://127.0.0.1:5555',
    reuseExistingServer: true,
  },
});
