# IS-373-TEST-CICD

**Production:** https://acw33firstliveproj.online
**QA:** https://qa.acw33firstliveproj.online

A small website that is validated, built into a Docker image, pushed to GitHub Container Registry, and deployed automatically to a DigitalOcean droplet through GitHub Actions. QA and production are separate containers behind Caddy with HTTPS.

## Branch and promotion rule

| Branch | Deploys to | URL |
|---|---|---|
| `qa` | QA | https://qa.acw33firstliveproj.online |
| `main` | Production | https://acw33firstliveproj.online |

1. Make and commit changes on the `qa` branch, then push. The pipeline deploys to QA only.
2. Check the change on the QA site.
3. Open a pull request from `qa` into `main` and merge it. The pipeline deploys to production.

QA and production run as separate containers with separate image tags (`qa-<sha>` and `prod-<sha>`), so a QA deploy never touches production.

## How the pipeline works

- **Trigger:** every push to `qa` or `main` (and manual runs from the Actions tab).
- **Test job:** checks the site files exist and are valid HTML structure, checks the shell scripts parse, validates the Compose file and the Caddyfile. A failure here stops everything.
- **Build job:** builds the Docker image, runs it and smoke-tests it (page loads, version stamp matches the commit), then pushes it to `ghcr.io/acw900/is-373-test-cicd` tagged `<env>-<short sha>` and `<env>-latest`. A failed build stops deployment.
- **Deploy job:** connects to the server over SSH with a dedicated deploy key, copies the deployment files, pulls the new image, restarts only the target environment, waits for its health check (rolling back if it never becomes healthy), then checks that the live site reports the commit that was just pushed.
- **Secrets:** `SSH_PRIVATE_KEY`, `SERVER_HOST`, `SERVER_USER`, `SERVER_PORT` live in GitHub Actions secrets. Nothing sensitive is in this repository.

## Repository layout

```
.github/workflows/deploy.yml   CI/CD pipeline
Dockerfile                     image build (nginx serving site/)
site/                          website source
deploy/docker-compose.yml      Caddy + QA + production containers (runs on the server)
deploy/Caddyfile               HTTPS routing for production and QA
deploy/deploy.sh               per-environment deploy with health check and rollback
scripts/validate.sh            basic validation used by the test job
```

## Run locally

```bash
docker build -t is373-site .
docker run --rm -p 8080:80 is373-site
```

Open http://localhost:8080

## Test Evidence

> Replace every TODO below before submitting.

**Workflow runs and image**

- QA workflow run: TODO (link to the green run on the `qa` branch)
- Production workflow run: TODO (link to the green run on `main`)
- Image registry location: TODO (link from the repository's Packages section, `ghcr.io/acw900/is-373-test-cicd`)
- Deployed commit / image tag: TODO (for example `prod-abc1234`, from the run summary)

**The change moving through QA to production**

- Screenshot of the change on QA: TODO
- Screenshot of the same change on production after promotion: TODO

**SSH hardening (redacted)**

- Key-based login as the non-root user: TODO (screenshot or terminal output)
- Effective SSH settings showing root and password login disabled (`sudo sshd -T`): TODO
- Root login rejected: TODO
- Password login rejected: TODO

**Summary**

CI runs on every push to `qa` or `main`. The test job validates the site files, shell scripts, Compose file and Caddyfile. The build job builds the Docker image, smoke-tests it, and pushes it to GitHub Container Registry. The deploy job connects to the droplet over SSH with a deploy key stored in GitHub Secrets, pulls the new image, restarts only that environment, and confirms the live site reports the commit that was pushed. `qa` goes to the QA subdomain; merging into `main` goes to production.
