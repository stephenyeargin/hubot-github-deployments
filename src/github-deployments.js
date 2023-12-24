// Description:
//   Integrate with GitHub deployment API
//
// Dependencies:
//   "githubot": "*"
//
// Configuration:
//   HUBOT_GITHUB_TOKEN - GitHub API token. Required to perform authenticated actions.
//   HUBOT_GITHUB_API - (optional) The base API URL. This is useful for Enterprise Github installations.
//   HUBOT_GITHUB_USER - Default GitHub username to use if one is not given.
//   HUBOT_GITHUB_REPO - GitHub repository to use for deployments
//   HUBOT_GITHUB_DEPLOY_TARGETS - comma separated keys for your deployment environments.
//   HUBOT_GITHUB_DEPLOY_AUTO_MERGE - (optional) Instructs GitHub to attempt to automatically merge the default branch into the requested ref.
//   HUBOT_GITHUB_DEPLOY_REQUIRED_CONTEXTS - (optional) Instructs GitHub to attempt to perform a status check. Pass empty array to skip it.
// Commands:
//   hubot deploy status [for :owner/:repo] - List the status of most recent deployments
//   hubot deploy status [id] [for :owner/:repo]  - List the statuses a particular deployment, or an optional specific status
//   hubot deploy list targets - List available deployment targets
//   hubot deploy list branches [for :owner/:repo] [search] - List available branches, filtered by optional search term
//   hubot deploy <branch or SHA> to <server> [for :owner/:repo]  - Creates a Github deployment of a branch/SHA to a server
//
// Notes:
//   HUBOT_GITHUB_DEPLOYMENT_TARGETS defines what is sent along with the payload for your third-party tool
//   If HUBOT_GITHUB_REPO is not provided, you'll need to include the `for :owner/:repo` syntax
//
// Author:
//   stephenyeargin
//

const GitHub = require('githubot');

module.exports = (robot) => {
  let deployTargets;
  const github = GitHub(robot, { apiVersion: 'cannonball-preview' });
  if (process.env.HUBOT_GITHUB_DEPLOY_TARGETS) {
    deployTargets = process.env.HUBOT_GITHUB_DEPLOY_TARGETS.split(',');
  } else {
    deployTargets = [];
  }

  // Get repo settings
  const getRepoInfo = (match1, match2) => {
    let app = process.env.HUBOT_GITHUB_REPO;
    let owner = process.env.HUBOT_GITHUB_OWNER;
    if ((owner == null)) {
      owner = match1;
    }
    const repo = match2;

    if ((owner == null) && (repo == null)) {
      if ((app == null)) {
        app = '';
      }
    } else {
      app = `${owner}/${repo}`;
    }
    return app;
  };

  // Check Config
  const checkConfiguration = (res) => {
    if (!process.env.HUBOT_GITHUB_TOKEN) {
      res.send('Missing configuration: `HUBOT_GITHUB_TOKEN`');
      return false;
    }
    if (!process.env.HUBOT_GITHUB_USER) {
      res.send('Missing configuration: `HUBOT_GITHUB_USER`');
      return false;
    }
    if (!process.env.HUBOT_GITHUB_DEPLOY_TARGETS) {
      res.send('Missing configuration: `HUBOT_GITHUB_DEPLOY_TARGETS`');
      return false;
    }

    return true;
  };

  // Status
  robot.respond(/deploy status( [0-9]+)?(?: for ([-A-z0-9]+)\/([-A-z0-9]+))?$/i, (res) => {
    if (!checkConfiguration(res)) {
      return;
    }

    let statusId = res.match[1];
    const app = getRepoInfo(res.match[2], res.match[3]);
    if ((app == null)) {
      res.send('Missing configuration: HUBOT_GITHUB_REPO');
      return;
    }

    if (statusId != null) {
      statusId = statusId.trim();
      github.deployments(app).status(statusId, (statuses) => {
        robot.logger.debug(statuses);
        if (statuses.length === 0) {
          res.send('No status updates available.');
          return;
        }
        statuses.map((s) => res.send(`Status: ${s.description} (${s.created_at}) / State: ${s.state}`));
      });
      return;
    }
    github.deployments(app, (deployments) => {
      robot.logger.debug(deployments);
      if (deployments.length === 0) {
        res.send('No recent deployments.');
        return;
      }
      deployments.map((d) => res.send(`Deployment ${d.id} (${d.created_at}): User: ${d.creator.login} / Action: ${d.task} / Ref: ${d.ref} / Environment: ${d.environment} / Description: (${d.description})`));
    });
  });

  // List Deployment Targets
  robot.respond(/deploy list targets$/i, (res) => {
    robot.logger.debug(deployTargets);
    if (!checkConfiguration(res)) {
      return;
    }
    if (deployTargets.length === 0) {
      res.send('No deployment targets defined. Set `HUBOT_GITHUB_DEPLOYMENT_TARGETS` first.');
      return;
    }
    res.send('Available Deployment Targets');
    deployTargets.map((target) => res.send(`- ${target}`));
  });

  // List Available Branches
  robot.respond(/deploy list branches(?: for ([-A-z0-9]+)\/([-A-z0-9]+))?(.*)$/i, (res) => {
    if (!checkConfiguration(res)) {
      return;
    }

    const app = getRepoInfo(res.match[1], res.match[2]);
    if ((app == null)) {
      res.send('Missing configuration: HUBOT_GITHUB_REPO');
      return;
    }

    const filter = res.match[3].toLowerCase().trim();

    github.branches(app, (branches) => {
      robot.logger.debug(branches);
      if (branches.length === 0) {
        res.send('No branches in repository.');
        return;
      }
      const filteredBranches = branches.filter((b) => b.name.toLowerCase().indexOf(filter) > -1);
      if (filteredBranches.length === 0) {
        res.send('No branches matched search criteria.');
        return;
      }

      res.send('Available Deployment Branches');
      filteredBranches.map((b) => res.send(`- ${b.name}: ${b.commit.sha}`));
    });
  });

  // Create Deployment
  robot.respond(/deploy ([-_.0-9a-zA-Z/]+)? to ([-_.0-9a-zA-Z/]+)(?: for ([-A-z0-9]+)\/([-A-z0-9]+))?$/i, (res) => {
    if (!checkConfiguration(res)) {
      return;
    }

    const app = getRepoInfo(res.match[3], res.match[4]);
    if ((app == null)) {
      res.send('Missing configuration: `HUBOT_GITHUB_REPO`');
      return;
    }
    const autoMerge = process.env.HUBOT_GITHUB_DEPLOY_AUTO_MERGE;
    const requiredContexts = process.env.HUBOT_GITHUB_DEPLOY_REQUIRED_CONTEXTS;
    const ref = res.match[1];
    const target = res.match[2];

    if (deployTargets.includes(target)) {
      const username = res.message.user.name.toLowerCase();
      const room = res.message.user.room.toLowerCase();

      const data = {
        ref,
        task: 'deploy',
        environment: target,
        payload: { user: username, room },
        description: `${username} created deployment for ${app}@${ref} to ${target}`,
      };

      if (autoMerge) {
        data.auto_merge = autoMerge === 'true';
      }
      if (requiredContexts) {
        data.required_contexts = requiredContexts;
      }

      github.deployments(app).create(ref, data, (deployment) => res.send(deployment.description));
      return;
    }
    res.send(`"${target}" not in available deploy targets. Use \`deploy list targets\``);
  });

  // Help
  robot.respond(/deploy$/i, (res) => {
    if (!checkConfiguration(res)) {
      return;
    }

    const commands = robot.helpCommands();
    const filteredCommands = commands.filter((cmd) => cmd.match(/deploy/i));
    let emit = filteredCommands.join('\n');
    if (robot.name.toLowerCase() !== 'hubot') {
      emit = emit.replace(/hubot/ig, robot.name);
    }
    res.send(emit);
  });
};
