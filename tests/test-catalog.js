#!/usr/bin/env node
'use strict';

// Validates catalog.json against the skills/ tree and exercises the bin/skill
// wrapper. Zero-dependency (Node builtins only).

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const LOCAL_REPO = 'knowttl/awesome-ai';

let passed = 0;
let failed = 0;
function ok(name) { passed++; process.stdout.write(`  \x1b[32mPASS\x1b[0m ${name}\n`); }
function bad(name, detail) {
  failed++;
  process.stdout.write(`  \x1b[31mFAIL\x1b[0m ${name}${detail ? ` - ${detail}` : ''}\n`);
}
function assert(cond, name, detail) { cond ? ok(name) : bad(name, detail); }

// Read the frontmatter `name:` from a SKILL.md file.
function frontmatterName(file) {
  const text = fs.readFileSync(file, 'utf8');
  const m = text.match(/^name:\s*(.+)$/m);
  return m ? m[1].trim() : null;
}

// --- load catalog ---
let catalog;
try {
  catalog = JSON.parse(fs.readFileSync(path.join(ROOT, 'catalog.json'), 'utf8'));
  ok('catalog.json is valid JSON');
} catch (e) {
  bad('catalog.json is valid JSON', e.message);
  process.exit(1);
}

assert(catalog.items && typeof catalog.items === 'object', 'catalog has items');
assert(catalog.bundles && typeof catalog.bundles === 'object', 'catalog has bundles');

// --- every item has a repo ---
for (const [name, item] of Object.entries(catalog.items)) {
  assert(item.repo, `item "${name}" has a repo`);
}

// --- every bundle references only known items ---
for (const [bundle, names] of Object.entries(catalog.bundles)) {
  for (const n of names) {
    assert(catalog.items[n], `bundle "${bundle}" -> "${n}" exists in items`);
  }
}

// --- map local skill dirs by frontmatter name ---
const skillsDir = path.join(ROOT, 'skills');
const localByName = {};
for (const dir of fs.readdirSync(skillsDir)) {
  const skillMd = path.join(skillsDir, dir, 'SKILL.md');
  if (fs.existsSync(skillMd)) {
    const name = frontmatterName(skillMd);
    if (name) localByName[name] = dir;
  }
}

// --- every local-repo catalog item resolves to a skill dir with matching name ---
const localItems = Object.entries(catalog.items).filter(([, i]) => i.repo === LOCAL_REPO);
for (const [name] of localItems) {
  const selector = catalog.items[name].skill || name;
  assert(localByName[selector], `local item "${name}" resolves to skills/${localByName[selector] || '???'} (frontmatter name "${selector}")`);
}

// --- every local skill dir is represented in the catalog (no orphans) ---
const localSelectorsInCatalog = new Set(localItems.map(([n]) => catalog.items[n].skill || n));
for (const [name, dir] of Object.entries(localByName)) {
  assert(localSelectorsInCatalog.has(name), `skills/${dir} (name "${name}") is listed in catalog`);
}

// --- files listed in each local manifest exist ---
for (const dir of fs.readdirSync(skillsDir)) {
  const manifest = path.join(skillsDir, dir, 'manifest.yaml');
  if (!fs.existsSync(manifest)) continue;
  const text = fs.readFileSync(manifest, 'utf8');
  const filesBlock = text.match(/^files:\s*\n((?:\s*-\s*.+\n?)+)/m);
  if (!filesBlock) continue;
  const files = [...filesBlock[1].matchAll(/-\s*(.+)/g)].map((m) => m[1].trim());
  for (const f of files) {
    assert(fs.existsSync(path.join(skillsDir, dir, f)), `skills/${dir}/${f} exists (listed in manifest)`);
  }
}

// --- the wrapper runs ---
const list = spawnSync('node', [path.join(ROOT, 'bin/skill'), 'list'], { encoding: 'utf8' });
assert(list.status === 0, 'bin/skill list exits 0');

const dry = spawnSync('node', [path.join(ROOT, 'bin/skill'), 'install', 'recommended', '--dry-run'], { encoding: 'utf8' });
assert(dry.status === 0 && /npx -y skills add/.test(dry.stdout), 'bin/skill install recommended --dry-run emits skills commands');

const unknown = spawnSync('node', [path.join(ROOT, 'bin/skill'), 'install', 'does-not-exist'], { encoding: 'utf8' });
assert(unknown.status !== 0, 'bin/skill rejects unknown target');

// --- summary ---
process.stdout.write(`\n  ${passed} passed, ${failed} failed\n`);
process.exit(failed === 0 ? 0 : 1);
