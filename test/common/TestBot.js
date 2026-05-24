const path = require('path');
const { Robot, TextMessage } = require('hubot');
const nock = require('nock');
const script = require('../../src/github-deployments');

class TestBotContext {
  constructor(robot, user) {
    this.robot = robot; this.user = user;
    this.sends = []; this.replies = [];
    this.robot.adapter.on('send', (_, strings) => this.sends.push(strings.join('\n')));
    this.robot.adapter.on('reply', (_, strings) => this.replies.push(strings.join('\n')));
    this.nock = nock;
  }

  async send(message) {
    const id = (Math.random() + 1).toString(36).substring(7);
    this.robot.adapter.receive(new TextMessage(this.user, message, id));
    await new Promise((done) => { setTimeout(done, 50); });
  }

  async sendAndWaitForResponse(message, responseType = 'send') {
    return new Promise((done) => {
      this.robot.adapter.once(responseType, (_, strings) => done(strings[0]));
      this.send(message);
    });
  }

  shutdown() {
    delete process.env.HUBOT_GITHUB_TOKEN;
    delete process.env.HUBOT_GITHUB_OWNER;
    delete process.env.HUBOT_GITHUB_REPO;
    delete process.env.HUBOT_GITHUB_USER;
    delete process.env.HUBOT_GITHUB_DEPLOY_TARGETS;
    delete process.env.HUBOT_GITHUB_DEPLOY_REQUIRED_CONTEXTS;
    delete process.env.HUBOT_GITHUB_DEPLOY_AUTO_MERGE;
    nock.cleanAll();
    this.robot.shutdown();
  }
}

async function createTestBot(settings = {}) {
  process.env.HUBOT_LOG_LEVEL = 'silent';
  process.env.HUBOT_GITHUB_TOKEN = 'foobarbaz';
  process.env.HUBOT_GITHUB_USER = 'hubot';
  process.env.HUBOT_GITHUB_DEPLOY_TARGETS = 'production,staging';
  process.env.HUBOT_GITHUB_REPO = 'stephenyeargin/hubot-github-deployments';
  nock.cleanAll();
  nock.disableNetConnect();
  const robot = new Robot(path.resolve(__dirname, 'adapter'), false, 'hubot');
  await robot.loadAdapter(path.resolve(__dirname, 'adapter.js'));
  script(robot);
  return new Promise((done) => {
    robot.adapter.on('connected', () => {
      if (settings.adapterName) robot.adapterName = settings.adapterName;
      const user = robot.brain.userForId('1', { name: 'alice', room: '#testroom' });
      done(new TestBotContext(robot, user));
    });
    robot.run();
  });
}

module.exports = { createTestBot, TestBotContext };
