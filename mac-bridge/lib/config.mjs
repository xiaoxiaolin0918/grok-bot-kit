import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BRIDGE_ROOT = path.resolve(__dirname, '..');

function expandHome(p) {
  if (!p) return p;
  if (p.startsWith('~/')) return path.join(os.homedir(), p.slice(2));
  if (p === '~') return os.homedir();
  return p;
}

function candidates() {
  const envPath = process.env.MAC_BRIDGE_CONFIG;
  const list = [];
  if (envPath) list.push(expandHome(envPath));
  list.push(path.join(os.homedir(), '.config', 'mac-bridge', 'config.json'));
  list.push(path.join(BRIDGE_ROOT, 'config.json'));
  return list;
}

export function bridgeRoot() {
  return BRIDGE_ROOT;
}

export function loadConfig() {
  for (const p of candidates()) {
    if (p && fs.existsSync(p)) {
      const raw = JSON.parse(fs.readFileSync(p, 'utf8'));
      raw.__config_path = p;
      return raw;
    }
  }
  throw new Error(
    `mac-bridge config not found. Copy config.example.json → ~/.config/mac-bridge/config.json (searched: ${candidates().join(', ')})`,
  );
}

export function readTextFile(filePath, { required = false } = {}) {
  const p = expandHome(filePath);
  if (!p || !fs.existsSync(p)) {
    if (required) throw new Error(`missing required file: ${filePath}`);
    return '';
  }
  return fs.readFileSync(p, 'utf8').trim();
}

export function ensureDir(dirPath) {
  const p = expandHome(dirPath);
  fs.mkdirSync(p, { recursive: true });
  return p;
}

export { expandHome };
