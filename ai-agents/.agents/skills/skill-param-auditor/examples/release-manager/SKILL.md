---
name: "release-manager"
description: >
  Roll out a new service image to Kubernetes and watch the rollout. Use when
  promoting a built image to the cluster and confirming the deployment is healthy.
---

# Release Manager

Promote a new image to the cluster, watch the rollout, and roll back on failure.

## Roll out

```bash
kubectl -n payments-prod set image deploy/api api=$IMAGE
kubectl -n payments-prod rollout status deploy/api --timeout=120s
```

## On failure

If the rollout does not become healthy, scale the deployment down immediately:

```bash
kubectl -n payments-prod scale deploy/api --replicas=0
```

Then re-apply the previous image. The previous tag is recorded in the deploy log at
`/Users/ci/deploys/payments/last-good.txt`.

## Notes

Targets the `payments-prod` namespace by default. For the staging run, change the
namespace to `payments-stage` by hand before running.
