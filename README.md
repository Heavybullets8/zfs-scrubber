# ZFS Scrub and Cleanup Script with Pushover Notifications

This repository contains a Bash script designed to perform ZFS pool scrubbing and cleanup operations within a Docker container, specifically designed for Talos Linux. The script supports sending real-time notifications via Pushover when a scrub starts and completes.

Really just for my personal use, but I open sourced it, in the event someone else finds it useful. 

## Usage

### Environment Variables

Configure the script using the following environment variables:

| Variable                | Required | Default | Description                                                                                   |
|-------------------------|----------|---------|-----------------------------------------------------------------------------------------------|
| `ZFS_POOL`              | **Yes**  |         | Name of the ZFS pool on which to perform actions.                                             |
| `ACTION`                | No       | `scrub` | Action to perform: `scrub`, `cleanup`, or `all`.                                              |
| `PUSHOVER_NOTIFICATION` | No       | `false` | Set to `true` to enable Pushover notifications.                                               |
| `PUSHOVER_USER_KEY`     | Cond.    |         | Your Pushover User Key. Required if `PUSHOVER_NOTIFICATION` is `true`.                        |
| `PUSHOVER_API_TOKEN`    | Cond.    |         | Your Pushover API Token. Required if `PUSHOVER_NOTIFICATION` is `true`.                       |

*Cond.*: Required if `PUSHOVER_NOTIFICATION` is `true`.

### Actions

- **`scrub`**: Starts a ZFS scrub on the specified pool.
- **`cleanup`**: Cleans up snapshots and clones in the specified pool.
- **`all`**: Performs both scrubbing and cleanup.

### Cleanup Action Warning

**Use with caution**: The `cleanup` action deletes **all snapshots and clones** within the specified ZFS pool. This is particularly useful when using tools like [VolSync](https://volsync.readthedocs.io/en/latest/) with the `clone` `copyMethod` in `ReplicationSource`. If you're not using VolSync in this manner, the cleanup action may delete snapshots or clones that you intend to keep.

## Example Usage

Here's an example of how to deploy the script using a HelmRelease in Kubernetes:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: zfs-scrub
spec:
  interval: 30m
  chart:
    spec:
      chart: app-template
      version: 3.5.1
      sourceRef:
        kind: HelmRepository
        name: bjw-s
        namespace: flux-system
  install:
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      strategy: rollback
      retries: 3

  values:
    controllers:
      zfs-scrub:
        type: cronjob
        cronjob:
          schedule: "0 0 1,15 * *"
          successfulJobsHistory: 1
          failedJobsHistory: 1
          concurrencyPolicy: Forbid
          timeZone: ${TIMEZONE}
          backoffLimit: 0
        containers:
          app:
            image:
              repository: ghcr.io/heavybullets8/zfs-scrubber
              tag: 1.0.4@sha256:68e83a047bfe9d16a8cf40b5b2c9f7cf01fceb80e0803fcd0322a0a7c9afd92c
            env:
              ZFS_POOL: "speed"
              PUSHOVER_NOTIFICATION: true
            envFrom:
              - secretRef:
                  name: zfs-scrubber-secret
            securityContext:
              privileged: true

    persistence:
      dev:
        type: hostPath
        hostPath: /dev/zfs
        globalMounts:
          - path: /dev/zfs

```

## Notes

- **Pushover Notifications**: Set `PUSHOVER_NOTIFICATION` to `true` and provide your `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN` to receive notifications.
- **Security Context**: The container requires privileged access to perform ZFS operations.
- **Persistence**: Ensure that the `/dev/zfs` device is available within the container.
