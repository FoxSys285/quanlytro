// Keep the existing Firebase CLI credential in memory, never print or persist it.
const path = require('node:path');
const { spawnSync } = require('node:child_process');

async function main() {
  const cli = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools');
  const auth = require(path.join(cli, 'lib/auth.js'));
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Run firebase login first.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
  ]);
  const args = process.argv.slice(2);
  if (!args.length) throw new Error('Expected a Python script and its arguments.');
  const result = spawnSync('python', args, {
    stdio: 'inherit',
    env: { ...process.env, FIREBASE_ACCESS_TOKEN: token.access_token, PYTHONUTF8: '1' },
  });
  process.exitCode = result.status ?? 1;
}
main().catch(() => {
  console.error('Firebase CLI authentication failed; no credentials were printed.');
  process.exitCode = 1;
});
