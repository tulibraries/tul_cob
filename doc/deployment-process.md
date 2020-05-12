QA, Stage and Production Deployments
====

### QA Deployments
* Deployments to the QA environment are triggered automatically by the CI service
  whenever a PR is merged to the master branch.

### Stage Deployments
* Stage deployments are triggered automatically by the CI service [when a new release
  is tagged](new-release-process.md).

### Production Deployments
* Production deployments are triggered on confirmation. The deployment
  confirmation is queued [when a new release is
  tagged](new-release-process.md).

## Production Deployment Checklist
Deployments to the production environment MUST adhere to the following checklist.

- [ ] Verify that all required updates have been made to tul_cob_playbook/master
- [ ] Before confirming a production for deployment check that the stage
  version is up and that you have confirmation that it is ready to be deployed.
- [ ] Announce on the #blacklight_project channel that deployment is about to take place.
- [ ] Allow a minute or two to get any objections via slack.
- [ ] Follow the deployment on the CI service in case there are issues.
- [ ] After the deployment is complete post success or failure on slack (to be automated).
- [ ] Smoke test the deployment.
