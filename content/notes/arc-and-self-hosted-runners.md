---
title: ARC & Self-Hosted Runners
---

## Actions Runner Controller (ARC)

ARC is a Kubernetes operator that manages GitHub Actions self-hosted runners. Instead of running persistent VMs waiting for jobs, ARC dynamically creates runner pods when GitHub dispatches jobs, and deletes them when done.

### Components

ARC has two layers:

- **Controller** — watches GitHub for pending jobs, manages runner lifecycle, communicates with GitHub's API. Runs on a dedicated node pool (the "controller" pool). This is a trusted component — it holds GitHub App credentials and manages authentication.
- **Runner pods** — ephemeral pods that execute the actual CI job. Created on-demand, destroyed after one job (ephemeral mode). Run on separate node pools.

### RunnerSets

A **RunnerSet** (or `AutoScalingRunnerSet`) defines a class of runners: what GitHub organization/repo it serves, what container image to use, resource limits, tolerations, and labels. Think of it as a template.

When GitHub dispatches a job with matching labels (e.g., `runs-on: [self-hosted, linux, large]`), ARC picks the RunnerSet whose labels match, and creates a runner pod from that template.

Multiple RunnerSets can target the **same node pool** — they just define different runner configurations. The node pool provides the compute; the RunnerSet provides the runner behavior.

### Scheduling Runners to Specific Node Pools

RunnerSets use standard Kubernetes scheduling:

- **nodeSelector** — select nodes by label (e.g., `mercari.com/instance-purpose: runner`)
- **tolerations** — allow scheduling on tainted nodes (e.g., tolerate `runner-type=image-cached:NoSchedule`)

This is how you control which runners land on which infrastructure. A RunnerSet for "high-availability" jobs tolerates the HA taint and only schedules on HA nodes.

See [[notes/cloud-nat-and-vpc-networking|Cloud NAT & VPC Networking]] for the NAT isolation pattern and [[notes/kubernetes|Kubernetes Concepts]] for node pool scheduling.
