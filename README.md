# Hubot GitHub Deployments

Integrate with GitHub deployment API

[![Build Status](https://travis-ci.org/stephenyeargin/hubot-github-deployments.png)](https://travis-ci.org/stephenyeargin/hubot-github-deployments)

## Getting Started

This module allows you to create payloads to send to the [GitHub Deployment API](https://developer.github.com/v3/repos/deployments/), then check on the status of the deployments. Combined with a deployment tool that listens to organizational or repository [DeploymentEvent](https://developer.github.com/v3/activity/events/types/#deploymentevent) webhooks, this module can help automate that process via ChatOps.

## Installation

In your hubot repository, run:

`npm install hubot-github-deployments --save`

Then add **hubot-github-deployments** to your `external-scripts.json`:

```json
["hubot-github-deployments"]
```

## Configuration:

### Heroku

```
heroku config:set HUBOT_GITHUB_TOKEN=<User Application Token>
heroku config:set HUBOT_GITHUB_USER=<User for Deployments>
heroku config:set HUBOT_GITHUB_DEPLOY_TARGETS=<Comma Seperated List of Environments>
heroku config:set HUBOT_GITHUB_REPO=<Repository to deploy, in :user_or_org/:repository format>
```

### Standard

```
export HUBOT_GITHUB_TOKEN=<User Application Token>
export HUBOT_GITHUB_USER=<User for Deployments>
export HUBOT_GITHUB_DEPLOY_TARGETS=<Comma Seperated List of Environments>
export HUBOT_GITHUB_REPO=<Repository to deploy, in :user_or_org/:repository format>
```

## Commands:

- `hubot deploy status` - List the status of most recent deployments
- `hubot deploy status <id>` - List the statuses a particular deployment
- `hubot deploy list targets` - List available deployment targets
- `hubot deploy list branches <search>` - List available branches, filtered by optional search term
- `hubot deploy <branch or SHA> to <server>` - Creates a Github deployment of a branch/SHA to a server
