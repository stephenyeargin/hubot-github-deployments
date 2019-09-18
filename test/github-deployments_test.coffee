Helper = require('hubot-test-helper')
chai = require 'chai'
nock = require 'nock'

expect = chai.expect

helper = new Helper [
  '../src/github-deployments.coffee'
]

describe 'hubot-github-deployments', ->
  beforeEach ->
    process.env.HUBOT_GITHUB_TOKEN='foobarbaz'
    process.env.HUBOT_GITHUB_USER='hubot'
    process.env.HUBOT_GITHUB_DEPLOY_TARGETS='production,staging'
    process.env.HUBOT_GITHUB_REPO='stephenyeargin/hubot-github-deployments'
    nock.disableNetConnect()
    @room = helper.createRoom()

  afterEach ->
    delete process.env.HUBOT_GITHUB_TOKEN
    delete process.env.HUBOT_GITHUB_USER
    delete process.env.HUBOT_GITHUB_DEPLOY_TARGETS
    delete process.env.HUBOT_GITHUB_REPO
    nock.cleanAll()
    @room.destroy()

  it 'responds with the list of recent deployments', (done) ->
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/deployments')
      .replyWithFile(200, __dirname + '/fixtures/deployments.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy status')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy status']
          ['hubot', 'Deployment 1 (2012-07-20T01:19:13Z): User: octocat / Action: deploy / Ref: master / Environment: production / Description: (Deploy request from hubot)']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'responds with the list of recent deployments for a specific repo', (done) ->
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/deployments')
      .replyWithFile(200, __dirname + '/fixtures/deployments.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy status for someone/somewhere')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy status for someone/somewhere']
          ['hubot', 'Deployment 1 (2012-07-20T01:19:13Z): User: octocat / Action: deploy / Ref: master / Environment: production / Description: (Deploy request from hubot)']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'gets the status of a single deployment', (done) ->
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/deployments/1/statuses')
      .replyWithFile(200, __dirname + '/fixtures/deployments-1-statuses.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy status 1')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy status 1']
          ['hubot', 'Status: Deployment finished successfully. (2012-07-20T01:19:13Z) / State: success']
        ]
        done()
      catch err
        done err
      return
    , 1000)


  it 'gets the status of a single deployment for a specific repo', (done) ->
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/deployments/1/statuses')
      .replyWithFile(200, __dirname + '/fixtures/deployments-1-statuses.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy status 1 for someone/somewhere')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy status 1 for someone/somewhere']
          ['hubot', 'Status: Deployment finished successfully. (2012-07-20T01:19:13Z) / State: success']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'creates a deployment', (done) ->
    nock('https://api.github.com')
      .post('/repos/stephenyeargin/hubot-github-deployments/deployments')
      .replyWithFile(200, __dirname + '/fixtures/deployments-create.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy master to production')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy master to production']
          ['hubot', 'stephenyeargin deployed master to production']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'creates a deployment for a specific repo', (done) ->
    nock('https://api.github.com')
      .post('/repos/someone/somewhere/deployments')
      .replyWithFile(200, __dirname + '/fixtures/deployments-create.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy master to production for someone/somewhere')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy master to production for someone/somewhere']
          ['hubot', 'stephenyeargin deployed master to production']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists the target environments', (done) ->
    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list targets')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list targets']
          ['hubot', 'Available Deployment Targets']
          ['hubot', '- production']
          ['hubot', '- staging']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists all branches', (done) ->
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists all branches for a specific repo', (done) ->
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches for someone/somewhere')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches for someone/somewhere']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e']
        ]
        done()
      catch err
        done err
      return
    , 1000)


  it 'lists branches matching search', (done) ->
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches mast')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches mast']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists branches matching search for a specific repo', (done) ->
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches for someone/somewhere mast')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches for someone/somewhere mast']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- master: 6dcb09b5b57875f334f61aebed695e2e4193db5e']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists branches matching search, no results', (done) ->
    nock('https://api.github.com')
      .get('/repos/stephenyeargin/hubot-github-deployments/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches foo')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches foo']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- None matched search criteria.']
        ]
        done()
      catch err
        done err
      return
    , 1000)

  it 'lists branches matching search for a specific repo, no results', (done) ->
    nock('https://api.github.com')
      .get('/repos/someone/somewhere/branches')
      .replyWithFile(200, __dirname + '/fixtures/repos-branches.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot deploy list branches for someone/somewhere foo')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot deploy list branches for someone/somewhere foo']
          ['hubot', 'Available Deployment Branches']
          ['hubot', '- None matched search criteria.']
        ]
        done()
      catch err
        done err
      return
    , 1000)
