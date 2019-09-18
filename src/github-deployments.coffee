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
#   hubot deploy status (for owner/repo) - List the status of most recent deployments
#   hubot deploy status <id> (for owner/repo)  - List the statuses a particular deployment
#   hubot deploy list targets - List available deployment targets
#   hubot deploy list branches (for owner/repo) <search> - List available branches, filtered by optional search term
#   hubot deploy <branch or SHA> to <server> (for owner/repo)  - Creates a Github deployment of a branch/SHA to a server
#
# Notes:
#   HUBOT_GITHUB_DEPLOYMENT_TARGETS defines what is sent along with the payload for your third-party tool
#   If HUBOT_GITHUB_REPO is not provided, you'll need to include the `for :owner/:repo` syntax
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
  robot.respond /deploy status( [0-9]+)?(?: for ([\-A-z0-9]+)\/([\-A-z0-9]+))?$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    app = process.env.HUBOT_GITHUB_REPO
    status_id = msg.match[1]

    owner = msg.match[2]
    repo = msg.match[3]

    if !owner? && !repo?
      if !app?
        msg.send "Missing configuration: HUBOT_GITHUB_REPO"
        return false
    else
      app = "#{owner}/#{repo}"

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
  robot.respond /deploy list branches(?: for ([\-A-z0-9]+)\/([\-A-z0-9]+))?(.*)$/i, (msg) ->
    unless checkConfiguration(msg)
      return;


    app = process.env.HUBOT_GITHUB_REPO
    owner = msg.match[1]
    repo = msg.match[2]

    if !owner? && !repo?
      if !app?
        msg.send "Missing configuration: HUBOT_GITHUB_REPO"
        return false
    else
      app = "#{owner}/#{repo}"

    filter = msg.match[3].toLowerCase().trim()

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
  robot.respond /deploy ([-_\.0-9a-zA-Z\/]+)? to ([-_\.0-9a-zA-Z\/]+)(?: for ([\-A-z0-9]+)\/([\-A-z0-9]+))?$/i, (msg) ->
    unless checkConfiguration(msg)
      return;

    app = process.env.HUBOT_GITHUB_REPO
    ref = msg.match[1]
    target = msg.match[2]

    if target in deployTargets
      username = msg.message.user.name.toLowerCase()
      room = msg.message.user.room.toLowerCase()

      owner = msg.match[3]
      repo = msg.match[4]

      if !owner? && !repo?
        if !app?
          msg.send "Missing configuration: HUBOT_GITHUB_REPO"
          return false
      else
        app = "#{owner}/#{repo}"

      options = {
        ref: ref,
        task: 'deploy',
        environment: target,
        payload: {user: username, room: room}
        description: "#{username} deployedzzz #{ref} to #{target}"
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

    return true;
