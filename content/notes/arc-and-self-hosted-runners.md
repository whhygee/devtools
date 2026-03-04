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

### Runner Groups

Runner groups control which repositories can use which runners. They're configured at the GitHub org level (Settings → Actions → Runner groups).

**Key properties:**

- Runner labels (`runnerScaleSetName`) only need to be unique **within** a runner group, not across the entire org. Two different groups can each have a runner labeled `dev`.
- A repository's `runs-on` label is matched against runners in **all groups the repo has access to**. If a repo can see both Group A and Group B, and both have a runner labeled `dev`, GitHub could route to either.
- To control routing, restrict repo access at the group level. A repo in only Group A will only match runners from Group A.

**Per-repo runner routing without changing workflows:**

You can route specific repos to different infrastructure (e.g., a dedicated NAT, a special node pool) without modifying any workflow files:

1. Create a new runner group (e.g., `Isolated`)
2. Deploy a RunnerSet that registers under this group with the **same label** as your standard runner (e.g., `dev`)
3. The RunnerSet's pod template targets different infrastructure (different nodeSelector, tolerations, etc.)
4. Add the target repo to the `Isolated` group and remove it from the default group
5. The repo's existing `runs-on: [self-hosted, linux, dev]` now routes to the isolated runner — no workflow changes

**Gotcha:** If a repo has access to multiple groups with the same runner label, the job may land on any matching runner. Always remove the repo from the old group when migrating to avoid ambiguous routing.

### Full Chain: Runner Group → Egress IP

```
Runner Group (repo access control)
  → RunnerSet (label match via runs-on)
    → nodeSelector + tolerations (pod scheduling)
      → Node Pool (with a specific pod IP range)
        → Cloud NAT (targets that pod range)
          → Static egress IP
```

Each layer is configured independently. To give a set of repos a dedicated egress IP, you set up the chain bottom-up (NAT → node pool → RunnerSet → runner group) and control access top-down (assign repos to the group). See [[notes/cloud-nat-and-vpc-networking|Cloud NAT & VPC Networking]] for the NAT half of the chain.
