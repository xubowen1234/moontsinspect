'use strict';
const cp = require('node:child_process');
const assert = require('node:assert/strict');
const expected = require('../toolchain.json');
const result = cp.spawnSync('moon', ['version', '--all'], {encoding:'utf8'});
assert.equal(result.status, 0, result.stderr || 'moon version failed');
for (const name of ['moon','moonc','moonrun']) {
  assert.ok(result.stdout.split(/\r?\n/).some(line => line.startsWith(name + ' ' + expected[name])),
    'Toolchain mismatch for ' + name + '; use toolchain.json. Review upgrades deliberately; do not bypass the format gate.\n' + result.stdout);
}
assert.equal(Number(process.versions.node.split('.')[0]), expected.nodeMajor, 'Use the tested Node major');
console.log('PASS: exact MoonBit compiler/tool versions and Node major match toolchain.json');
