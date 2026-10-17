import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export function parseEnv(text) {
  const result = {};
  for (const line of text.replace(/^\uFEFF/, '').split(/\r?\n/)) {
    const match = line.trim().match(/^(?:export\s+)?([\w]+)\s*=\s*(.*)$/);
    if (!match) continue;
    let value = match[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    } else {
      value = value.replace(/\s+#.*$/, '').trim();
    }
    result[match[1]] = value;
  }
  return result;
}

export function loadConfig() {
  const path = process.env.AI_ENV_FILE || fileURLToPath(new URL('../lib/ai.env', import.meta.url));
  let local = {};
  try { local = parseEnv(readFileSync(path, 'utf8')); } catch (error) {
    if (error.code !== 'ENOENT') throw new Error('Không đọc được tệp cấu hình AI.');
  }
  const apiKey = process.env.ANTHROPIC_API_KEY || local.ANTHROPIC_API_KEY || local.claude_key;
  const base = process.env.AI_BASE_URL || local.AI_BASE_URL || local.base;
  if (!apiKey || !base) throw new Error('Thiếu claude_key hoặc base trong lib/ai.env.');
  const url = new URL(base);
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) {
    throw new Error('base phải là địa chỉ HTTPS hợp lệ, không chứa thông tin đăng nhập.');
  }
  return {
    apiKey,
    base: base.replace(/\/+$/, ''),
    model: process.env.AI_MODEL || local.AI_MODEL || 'claude-haiku-4-5-20251001',
    host: process.env.AI_HOST || '127.0.0.1',
    port: Number(process.env.AI_PORT || 8765),
  };
}
