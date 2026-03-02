---
title: GAR Virtual Repositories
---

## What they are

Google Artifact Registry (GAR) supports three repository modes:

- **Standard** — you push images to it directly (like any private registry)
- **Remote** — a pull-through cache for an upstream registry (Docker Hub, GitHub Container Registry, etc.). First pull fetches from upstream and caches; subsequent pulls are served from cache
- **Virtual** — a single endpoint that fans out to multiple backing repos, resolved by priority

Virtual repos don't store images themselves. They're a routing layer. You configure a list of backing repos (standard or remote), each with a numeric priority. When a client pulls an image, the virtual repo checks each backing repo in priority order and serves the first match.

## Why virtual repos are useful

The main value is **a single stable endpoint** that abstracts over multiple sources:

- Clients (Docker daemons, CI runners, K8s clusters) configure one registry URL
- You can add, remove, or re-prioritize backing repos without touching any client config
- Mix private images (standard repos) with cached upstream images (remote repos) behind one address

## Repository layout example

```
virtual-repo (single endpoint clients point at)
  ├── Priority 1: internal-images    (standard — your org's images)
  ├── Priority 2: dockerhub-cache    (remote — pull-through cache for Docker Hub)
  └── Priority 3: ghcr-cache         (remote — pull-through cache for GHCR)
```

A pull for `nginx:latest` checks internal-images first, then dockerhub-cache, then ghcr-cache. First match wins.

## Remote repos as pull-through caches

Remote repos are especially useful for:

- **Rate limit avoidance** — Docker Hub's pull rate limits don't apply to cached images
- **Faster pulls** — cached images are served from GCP, not fetched cross-network
- **Resilience** — if the upstream registry has an outage, cached images still serve

Remote repos cache on first pull. Subsequent pulls check upstream for freshness (by digest) but serve from cache if unchanged.

### Note - Docker mirror `library/` prefix

When using a virtual repo as a Docker `--registry-mirror`, Docker's mirror protocol prepends `library/` to official images. `FROM golang:1.25` becomes a request for `library/golang:1.25` at the mirror. Images in your standard backing repo must be pushed under `library/golang` (not just `golang`), or the mirror won't find them.

---

## Use case: transparent base image replacement

When you need to patch base images across many Dockerfiles without changing any of them, a virtual repo lets you overlay custom images on top of Docker Hub transparently.

### The problem I faced

`FROM golang:1.24-bookworm` pulls a stock image. Inside that image, tools have default settings — no org-specific config, no custom credentials, generic user-agent. The CI runner's host config does **not** propagate into Docker build containers or DinD sidecars. Each `docker build` starts fresh, and you can't fix this by configuring the runner.

### The approach we took

1. Build patched base images with the config you need baked in and push them to a standard GAR repo
2. Create a virtual repo that prioritizes your standard repo over a Docker Hub pull-through cache
3. Point Docker's `--registry-mirror` at the virtual repo

```
virtual-repo (mirror endpoint)
  ├── Priority 1: custom-images    (standard — patched base images)
  └── Priority 2: dockerhub-cache  (remote — pull-through for Docker Hub)
```

`FROM golang:1.24-bookworm` silently resolves to your patched image. Images you haven't patched fall through to Docker Hub as normal. No Dockerfile or workflow changes needed.

### Configuring the mirror

`--registry-mirror` is a **Docker daemon (`dockerd`) flag**, set on the DinD sidecar's startup args in Kubernetes:

```yaml
containers:
  - name: dind
    args:
      - dockerd
      - --registry-mirror=https://<region>-docker.pkg.dev/<project>/<virtual-repo>
```
