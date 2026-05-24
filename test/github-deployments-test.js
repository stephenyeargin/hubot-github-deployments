const {
  describe, it, beforeEach, afterEach,
} = require('node:test');
const assert = require('node:assert/strict');
const nock = require('nock');
const { createTestBot } = require('./common/TestBot');

describe('hubot-github-deployments', () => {
  let bot;

  beforeEach(async () => {
    bot = await createTestBot();
  });

  afterEach(() => {
    bot.shutdown();
  });

  it('responds with the list of recent deployments', async () => {
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/deployments')
      .replyWithFile(200, `${__dirname}/fixtures/deployments.json`);

    await bot.send('hubot deploy status');
    assert.deepEqual(bot.sends, [
      'Deployment 1 (2012-07-20T01:19:13Z): User: octocat / Action: deploy / Ref: master / Environment: production / Description: (Deploy request from hubot)',
    ]);
  });

  it('responds with the list of recent deployments for a specific repo', async () => {
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/deployments')
      .replyWithFile(200, `${__dirname}/fixtures/deployments.json`);

    await bot.send('hubot deploy status for someone/somewhere');
    assert.deepEqual(bot.sends, [
      'Deployment 1 (2012-07-20T01:19:13Z): User: octocat / Action: deploy / Ref: master / Environment: production / Description: (Deploy request from hubot)',
    ]);
  });

  it('gets the status of a single deployment', async () => {
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/deployments/1/statuses')
      .replyWithFile(200, `${__dirname}/fixtures/deployments-1-statuses.json`);

    await bot.send('hubot deploy status 1');
    assert.deepEqual(bot.sends, [
      'Status: Deployment finished successfully. (2012-07-20T01:19:13Z) / State: success',
    ]);
  });

  it('gets the status of a single deployment for a specific repo', async () => {
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/deployments/1/statuses')
      .replyWithFile(200, `${__dirname}/fixtures/deployments-1-statuses.json`);

    await bot.send('hubot deploy status 1 for someone/somewhere');
    assert.deepEqual(bot.sends, [
      'Status: Deployment finished successfully. (2012-07-20T01:19:13Z) / State: success',
    ]);
  });

  it('creates a deployment', async () => {
    nock('https://api.github.com')
      .post('/repos/stephenyeargin/hubot-github-deployments/deployments')
      .replyWithFile(200, `${__dirname}/fixtures/deployments-create.json`);

    await bot.send('hubot deploy master to production');
    assert.deepEqual(bot.sends, [
      'stephenyeargin deployed master to production',
    ]);
  });

  it('creates a deployment for a specific repo', async () => {
    nock('https://api.github.com')
      .post('/repos/someone/somewhere/deployments')
      .replyWithFile(200, `${__dirname}/fixtures/deployments-create.json`);

    await bot.send('hubot deploy master to production for someone/somewhere');
    assert.deepEqual(bot.sends, [
      'stephenyeargin deployed master to production',
    ]);
  });

  it('lists the target environments', async () => {
    await bot.send('hubot deploy list targets');
    assert.deepEqual(bot.sends, [
      'Available Deployment Targets',
      '- production',
      '- staging',
    ]);
  });

  it('lists all branches', async () => {
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches');
    assert.deepEqual(bot.sends, [
      'Available Deployment Branches',
      '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e',
    ]);
  });

  it('lists all branches for a specific repo', async () => {
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches for someone/somewhere');
    assert.deepEqual(bot.sends, [
      'Available Deployment Branches',
      '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e',
    ]);
  });

  it('lists branches matching search', async () => {
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches mast');
    assert.deepEqual(bot.sends, [
      'Available Deployment Branches',
      '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e',
    ]);
  });

  it('lists branches matching search for a specific repo', async () => {
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches for someone/somewhere mast');
    assert.deepEqual(bot.sends, [
      'Available Deployment Branches',
      '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e',
    ]);
  });

  it('lists branches matching search, no results', async () => {
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches foo');
    assert.deepEqual(bot.sends, [
      'No branches matched search criteria.',
    ]);
  });

  it('lists branches matching search for a specific repo, no results', async () => {
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, `${__dirname}/fixtures/repos-branches.json`);

    await bot.send('hubot deploy list branches for someone/somewhere foo');
    assert.deepEqual(bot.sends, [
      'No branches matched search criteria.',
    ]);
  });
});
