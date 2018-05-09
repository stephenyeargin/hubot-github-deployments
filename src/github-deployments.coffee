# Description:
#   Integrate with GitHub deployment API
#
# Dependencies:
#   "githubot": "*"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN - GitHub API token. Required to perform authenticated actions.
#   HUBOT_GITHUB_API - (optional) The base API URL. This is useful for Enterprise Github installations.
#   HUBOT_GITHUB_USER - Default GitHub username to use if one is not given.
#   HUBOT_GITHUB_DEPLOY_TARGETS - comma separated keys for your deployment environments.
#   HUBOT_GITHUB_REPO - GitHub repository to use for deployments
#
# Commands:
#   hubot deploy status - List the status of most recent deployments
#   hubot deploy status <id> - List the statuses a particular deployment
#   hubot deploy list targets - List available deployment targets
#   hubot deploy list branches <search> - List available branches, filtered by optional search term
#   hubot deploy <branch or SHA> to <server> - Creates a Github deployment of a branch/SHA to a server
#
# Notes:
#   HUBOT_GITHUB_DEPLOYMENT_TARGETS defines what is sent along with the payload for your third-party tool
#
# Author:
#   stephenyeargin

module.exports = (robot) ->
  github = require('githubot')(robot, apiVersion: 'cannonball-preview')
  if (process.env.HUBOT_GITHUB_DEPLOY_TARGETS)
    deployTargets = process.env.HUBOT_GITHUB_DEPLOY_TARGETS.split(",")
  else
    deployTargets = []

  # Status
  robot.respond /deploy status( [0-9]+)?$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    app = process.env.HUBOT_GITHUB_REPO
    status_id = msg.match[1]

    if status_id?
      status_id = status_id.trim()
      github.deployments(app).status status_id, (statuses) ->
        if statuses.length is 0
          msg.send "No status updates available."
        else
          for status in statuses
            do (status) ->
              msg.send "Status: #{status.description} (#{status.created_at}) / State: #{status.state}"
    else
      github.deployments app, (deployments) ->

        if deployments.length is 0
          msg.send "No recent deployments."
        else
          for deployment in deployments
            do (deployment) ->
              msg.send "Deployment #{deployment.id} (#{deployment.created_at}): User: #{deployment.creator.login} / Action: #{deployment.task} / Ref: #{deployment.ref} / Environment: #{deployment.environment} / Description: (#{deployment.description})"


  # List Deployment Targets
  robot.respond /deploy list targets$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    if deployTargets.length is 0
      msg.send "No deployment targets defined. Set HUBOT_GITHUB_DEPLOYMENT_TARGETS first."
    else
      msg.send "Available Deployment Targets"
      msg.send "- #{target}" for target in deployTargets

  # List Available Branches
  robot.respond /deploy list branches(.*)$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    filter = msg.match[1].toLowerCase().trim()

    app = process.env.HUBOT_GITHUB_REPO
    github.branches app, (branches) ->

      if branches.length is 0
        msg.send "No branches in repository."
      else
        msg.send "Available Deployment Branches"
        branch_count = 0
        for branch in branches
          do (branch) ->
            # Filtered list
            if filter
              branch_name = branch.name
              if ~branch_name.indexOf filter
                branch_count++
                msg.send "- #{branch.name}: #{branch.commit.sha}"
            # Unfiltered list
            else
              branch_count++
              msg.send "- #{branch.name}: #{branch.commit.sha}"
        if filter && branch_count == 0
          msg.send "- None matched search criteria."

  # Create Deployment
  robot.respond /deploy ([-_\.0-9a-zA-Z\/]+)? to ([-_\.0-9a-zA-Z\/]+)$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    app = process.env.HUBOT_GITHUB_REPO
    ref = msg.match[1]
    target = msg.match[2]

    if target in deployTargets
      username = msg.message.user.name.toLowerCase()
      room = msg.message.user.room.toLowerCase()

      options = {
        ref: ref,
        task: 'deploy',
        environment: target,
        payload: {user: username, room: room}
        description: "#{username} deployed #{ref} to #{target}"
      }

      github.deployments(app).create ref, options, (deployment) ->
        msg.send deployment.description
    else
      msg.send "\"#{target}\" not in available deploy targets. Use `deploy list targets`"

  # Help
  robot.respond /deploy$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    cmds = robot.helpCommands()
    cmds = cmds.filter (cmd) ->
      cmd.match new RegExp('deploy', 'i')
    emit = cmds.join "\n"
    unless robot.name.toLowerCase() is 'hubot'
      emit = emit.replace /hubot/ig, robot.name
    msg.send emit

  # Check Config
  checkConfiguration = (msg) ->
    unless process.env.HUBOT_GITHUB_TOKEN
      msg.send "Missing configuration: HUBOT_GITHUB_TOKEN"
      return false
    unless process.env.HUBOT_GITHUB_USER
      msg.send "Missing configuration: HUBOT_GITHUB_USER"
      return false
    unless process.env.HUBOT_GITHUB_DEPLOY_TARGETS
      msg.send "Missing configuration: HUBOT_GITHUB_DEPLOY_TARGETS"
      return false
    unless process.env.HUBOT_GITHUB_REPO
      msg.send "Missing configuration: HUBOT_GITHUB_REPO"
      return false

    return true;
