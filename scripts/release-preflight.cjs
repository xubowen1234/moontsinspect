'use strict';
// Read-only release gate. Provide the intended account through process-scoped
// GH_TOKEN; never switch global gh accounts or write credentials into this repo.
const cp = require('node:child_process');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const run = (command, args) => cp.execFileSync(command, args, {cwd:root, encoding:'utf8', stdio:['ignore','pipe','pipe']}).trim();
const gh = (...args) => JSON.parse(run('gh', args));
const owner = 'xubowen1234', repository = owner + '/moontsinspect';
assert.equal(run('git',['status','--porcelain']), '', 'Commit reviewed changes before release');
assert.equal(run('git',['remote','get-url','origin']), 'https://github.com/' + repository + '.git');
const actor = gh('api','user');
assert.equal(actor.login, owner); assert.equal(actor.id, 279239855);
const access = gh('repo','view',repository,'--json','nameWithOwner,isPrivate,viewerPermission,defaultBranchRef');
assert.equal(access.nameWithOwner, repository); assert.equal(access.isPrivate, false);
assert.equal(access.viewerPermission, 'ADMIN'); assert.equal(access.defaultBranchRef.name, 'main');
const head = run('git',['rev-parse','HEAD']);
const remoteHead = gh('api','repos/' + repository + '/commits/main');
assert.equal(remoteHead.sha, head, 'Default branch must equal the tested local release');
const local = run('git',['rev-list','HEAD']).split(/\r?\n/);
const commits = [];
for (let page = 1; ; page++) {
  const batch = gh('api','repos/' + repository + '/commits?sha=main&per_page=100&page=' + page);
  commits.push(...batch); if (batch.length < 100) break;
}
assert.deepEqual(commits.map(c=>c.sha).sort(), local.slice().sort());
for (const c of commits) {
  assert.equal(c.author && c.author.login, owner, 'Unverified author: ' + c.sha);
  assert.equal(c.committer && c.committer.login, owner, 'Unverified committer: ' + c.sha);
}
const runs = gh('run','list','--repo',repository,'--workflow','ci.yml','--commit',head,'--limit','30','--json','status,conclusion,headSha,url');
const passed = runs.find(r=>r.headSha===head && r.status==='completed' && r.conclusion==='success');
assert.ok(passed, 'No successful validation workflow for exact release HEAD');
console.log(JSON.stringify({repository,head,account:actor.login,verifiedCommits:commits.length,ci:passed.url,publication:'not performed by this read-only check'},null,2));
