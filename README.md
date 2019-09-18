# Hubot GitHub Deployments

[![npm version](https://badge.fury.io/js/hubot-github-deployments.svg)](http://badge.fury.io/js/hubot-github-deployments) [![Build Status](https://travis-ci.org/stephenyeargin/hubot-github-deployments.png)](https://travis-ci.org/stephenyeargin/hubot-github-deployments)

Integrate with GitHub deployment API.

## Getting Started

This package allows you to create payloads to send to the [GitHub Deployment API](https://developer.github.com/v3/repos/deployments/), then check on the status of the deployments. Combined with a deployment tool that listens to organizational or repository [DeploymentEvent](https://developer.github.com/v3/activity/events/types/#deploymentevent) webhooks, this module can help automate that process via ChatOps.

Note: This package is configured for use with a single repository to a static list of environments.

## Installation

In your hubot repository, run:

`npm install hubot-github-deployments --save`

Then add **hubot-github-deployments** to your `external-scripts.json`:

```json
["hubot-github-deployments"]
```

## Configuration:

| Environment Variable          | Required? | Description                      |
| ----------------------------- | :-------- | -------------------------------- |
| `HUBOT_GITHUB_TOKEN`          | Yes       | GitHub application token         |
| `HUBOT_GITHUB_USER`           | Yes       | GitHub bot user for deployments (IRC user will be noted in deployment description) |
| `HUBOT_GITHUB_DEPLOY_TARGETS` | Yes       | Comma-separated list of environments, e.g. `production,staging` |
| `HUBOT_GITHUB_REPO`           | No        | Repository to deploy, in `:owner/:repository format` |

## Commands:

- `hubot deploy status [for :owner/:repo]` - List the status of most recent deployments
- `hubot deploy status [id] [for :owner/:repo]` - List the statuses a particular deployment, or an optional specific status
- `hubot deploy list targets [for :owner/:repo]` - List available deployment targets
- `hubot deploy list branches [for :owner/:repo] [search]` - List available branches, filtered by optional search term
- `hubot deploy <branch or SHA> to <server> [for :owner/:repo]` - Creates a Github deployment of a branch/SHA to a server
