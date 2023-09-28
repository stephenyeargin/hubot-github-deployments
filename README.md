# Hubot GitHub Deployments

[![npm version](https://badge.fury.io/js/hubot-github-deployments.svg)](http://badge.fury.io/js/hubot-github-deployments) [![Node CI](https://github.com/stephenyeargin/hubot-github-deployments/actions/workflows/nodejs.yml/badge.svg)](https://github.com/stephenyeargin/hubot-github-deployments/actions/workflows/nodejs.yml)

Integrate with GitHub deployment API.

## Getting Started

This package allows you to create payloads to send to the [GitHub Deployment API](https://developer.github.com/v3/repos/deployments/), then check on the status of the deployments. Combined with a deployment tool that listens to organizational or repository [DeploymentEvent](https://developer.github.com/v3/activity/events/types/#deploymentevent) webhooks, this module can help automate that process via ChatOps.

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
| `HUBOT_GITHUB_DEPLOY_AUTO_MERGE` | No       | Passes auto_merge parameter to the deployment `true/false` |
| `HUBOT_GITHUB_DEPLOY_REQUIRED_CONTEXTS` | No       | Passes required_contexts parameter to the deployment `[]` |
| `HUBOT_GITHUB_REPO`           | No        | Repository to deploy, in `:owner/:repository`` format |
| `HUBOT_GITHUB_OWNER`          | No        | Repository owner for deploy/info `:owner`, let's us shorten `for :owner/:repository` format |

## Commands:

- `hubot deploy status [for :owner/:repo|:repo]` - List the status of most recent deployments
- `hubot deploy status [id] [for :owner/:repo|:repo]` - List the statuses a particular deployment, or an optional specific status
- `hubot deploy list targets [for :owner/:repo|:repo]` - List available deployment targets
- `hubot deploy list branches [for :owner/:repo|:repo] [search]` - List available branches, filtered by optional search term
- `hubot deploy <branch or SHA> to <server> [for :owner/:repo|:repo]` - Creates a Github deployment of a branch/SHA to a server
