import { expect, test } from '@playwright/test';
import { button, field, login, openApp, session, shot, text, typeInto } from './helpers';

test.describe('Authentication', () => {
  test('splash redirects to the sign-in screen', async ({ page }) => {
    await openApp(page, '/');
    await expect(button(page, 'Sign In')).toBeVisible();
    await expect(text(page, 'Sign in to your account')).toBeVisible();
    await shot(page, '01-login');
  });

  test('sign-in validates empty fields', async ({ page }) => {
    await openApp(page, '/login');
    await button(page, 'Sign In').click();
    await expect(text(page, 'Email is required')).toBeVisible();
    await expect(text(page, 'Password is required')).toBeVisible();
    await shot(page, '02-login-validation');
  });

  test('wrong password shows an inline error', async ({ page }) => {
    await openApp(page, '/login');
    await typeInto(field(page, 'Email'), session().email);
    await typeInto(field(page, 'Password'), 'not-the-password');
    await button(page, 'Sign In').click();
    await expect(text(page, 'Incorrect email or password')).toBeVisible();
    await shot(page, '03-login-wrong-password');
  });

  test('register a new account, then sign in with it', async ({ page }) => {
    const stamp = Date.now().toString(36);
    const email = `new.${stamp}@example.com`;
    await openApp(page, '/login');
    await button(page, 'Register').click();
    await expect(button(page, 'Create Account')).toBeVisible();
    await shot(page, '04-register');

    await typeInto(field(page, 'Username'), `rohan_${stamp}`);
    await typeInto(field(page, 'Email'), email);
    await typeInto(field(page, 'Password'), 'brand-new-pass');
    await button(page, 'Create Account').click();

    // Back on sign-in once the account exists.
    await expect(button(page, 'Sign In')).toBeVisible();
    await shot(page, '05-register-done');

    await login(page, { username: '', email, password: 'brand-new-pass' });
    // A brand-new account shows the empty dashboard.
    await expect(text(page, 'No notes yet')).toBeVisible();
    await shot(page, '06-dashboard-new-user');
  });

  test('forgot password asks for an email', async ({ page }) => {
    await openApp(page, '/login');
    await button(page, 'Forgot password?').click();
    await expect(button(page, 'Send reset code')).toBeVisible();
    await shot(page, '07-forgot-password');
  });
});
