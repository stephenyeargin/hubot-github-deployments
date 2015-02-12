chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'hubot-github-deployments', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/hubot-github-deployments')(@robot)

  it 'registers a respond deploy status listener', ->
    expect(@robot.respond).to.have.been.calledWith(/deploy status( [0-9]+)?$/i)

  it 'registers a respond list targets listener', ->
    expect(@robot.respond).to.have.been.calledWith(/deploy list targets$/i)

  it 'registers a respond list banches listener', ->
    expect(@robot.respond).to.have.been.calledWith(/deploy list branches(.*)$/i)

  it 'registers a respond deploy branch listener', ->
    expect(@robot.respond).to.have.been.calledWith(/deploy ([-_\.0-9a-zA-Z\/]+)? to ([-_\.0-9a-zA-Z\/]+)$/i)

  it 'registers a respond deploy help listener', ->
    expect(@robot.respond).to.have.been.calledWith(/deploy$/i)
