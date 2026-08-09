# HOKADIW Ubuntu Desktop Codespace

Ubuntu 24.04 development environment with:

- XFCE desktop in the browser through noVNC
- Docker Engine, Buildx, and Docker Compose v2
- Thai fonts and the `th_TH.UTF-8` locale
- Persistent repository files across Codespace restarts

## Create the Codespace

[Open this repository in GitHub Codespaces](https://codespaces.new/l2okjit-pro/ubuntu-desktop-codespace?quickstart=1)

Choose the 2-core machine. The first build installs the desktop packages and can take several minutes.

## Open Ubuntu Desktop

1. Wait for the Codespace setup to finish.
2. Open the **Ports** tab in VS Code.
3. Open port **6080 — Ubuntu Desktop (noVNC)** and keep its visibility **Private**.
4. Read the generated VNC password in the terminal:

```bash
cat ~/.config/hokadiw-desktop/password.txt
```

5. Enter that password in noVNC.

Desktop controls:

```bash
bash .devcontainer/start-desktop.sh status
bash .devcontainer/start-desktop.sh restart
bash .devcontainer/start-desktop.sh stop
```

Logs are stored in `~/.local/state/hokadiw-desktop/`.

## Test Docker

```bash
docker version
docker compose version
docker run --rm hello-world
```

Start the included Nginx example on forwarded port 8080:

```bash
docker compose up -d
```

Stop it with:

```bash
docker compose down
```

## Persistence and security

- Commit important work to GitHub before deleting the Codespace.
- Docker images and containers survive normal container restarts, but not Codespace deletion.
- Port 6080 is intended to remain Private and protected by GitHub authentication.
- A Codespace stops after inactivity and is not a 24/7 VPS.
