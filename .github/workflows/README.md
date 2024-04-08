# Running tests from Github workers

The shellspec tests from s3-tester `spec` folder can be triggered to run online using Github's
Actions web interface or using Github API's workflows endpoint.

## Via API

From: https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event

```
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR-TOKEN>" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/marmotitude/s3-tester/actions/workflows/manual-test.yml/dispatches \
  -d '{"ref":"main","inputs":{"profiles":"br-ne1,br-se1","clients":"mgc,rclone","tests":"1,15","container_image":"ghcr.io/marmotitude/s3-tester:tests"}}'
```

The token `<YOUR-TOKEN>` must have the permission `actions:write` and the `repo` scope.

## Via web interface

1. "[Actions](https://github.com/marmotitude/s3-tester/actions)"
1. "[Manually-triggered tests](https://github.com/marmotitude/s3-tester/actions/workflows/manual-test.yml)"
1. "Run Workflow" button
