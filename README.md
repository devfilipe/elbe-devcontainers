# elbe-devcontainers

Dev container for **ELBE – Embedded Linux Build Environment**.

Provides a ready-to-use Docker environment with ELBE, QEMU, libvirt, and
Debian packaging tools for building custom Linux images.

## Host requirements

| Requirement | Note |
|---|---|
| Docker + Docker Compose | Engine >= 20 recommended |
| `/dev/kvm` available | Required for QEMU/initvm |

## Quick start

> The full workspace is assembled via `repo` (Google Repo) from the
> [`elbe-demo-manifest`](https://github.com/devfilipe/elbe-demo-manifest).
> See `default.xml` for the list of repositories.

```bash
# 1. Clone the workspace (if not done yet)
mkdir elbe-workspace && cd elbe-workspace
repo init -u https://github.com/devfilipe/elbe-demo-manifest.git
repo sync

# 2. Start the container
cd tools/elbe-devcontainers
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose up -d

# 3. Enter the container
docker exec -it elbe-dev bash
```

## Create the initvm (one-time setup)

Inside the container:

```bash
elbe initvm create --qemu --directory /workspace/.elbe/initvm --skip-build-sources
```

> Takes ~15-30 min. The initvm is persisted at `/workspace/.elbe/initvm/`
> (Docker volume).

## Build an image

```bash
# Start the initvm (if stopped)
elbe initvm start --qemu --directory /workspace/.elbe/initvm

# Submit an XML for building
elbe initvm submit --qemu --directory /workspace/.elbe/initvm \
  --skip-build-sources --output /workspace/.elbe/output \
  /workspace/projects/elbe-demo-projects/<xml-name>.xml
```

Build artifacts are saved to `/workspace/.elbe/output/`.

## Boot the image on the host

```bash
cd .elbe/output
sudo chown -R $(id -u):$(id -g) .
tar -xf sda.img.tar.xz

# Serial console (no GUI)
qemu-system-x86_64 -m 1024 -drive file=sda.img,format=raw -nographic

# Graphical window
qemu-system-x86_64 -m 1024 -drive file=sda.img,format=raw
```

Default login: `root` / `root`

## Adding custom packages

The local APT repository is managed by
[`elbe-demo-apt-repository`](https://github.com/devfilipe/elbe-demo-apt-repository).

```bash
# 1. Inside the container: build the .deb and (re)generate the repo
cd /workspace/tools/elbe-demo-apt-repository
bash build-repo.sh

# 2. Submit the XML (with the repo configured in the XML)
elbe initvm submit --qemu --directory /workspace/.elbe/initvm \
  --skip-build-sources --output /workspace/.elbe/output \
  /workspace/projects/elbe-demo-projects/<xml-name>.xml
```

## ELBE UI

The container automatically starts the web interface
([`elbe-ui`](https://github.com/devfilipe/elbe-ui)) on port **8080**
(mapped to **8383** on the host).

Access it at: <http://localhost:8383>

## Exposed ports

| Port (container) | Port (host) | Service |
|---|---|---|
| 7587 | 7587 | ELBE initvm SOAP/XML-RPC |
| 8080 | 8383 | ELBE UI (web interface) |

## Workspace layout

```
elbe-workspace/                            # manifest repo root
├── .elbe/
│   ├── initvm/                        # build VM (persisted via volume)
│   └── output/                        # generated artifacts
├── projects/
│   └── elbe-demo-projects/            # ELBE XML image definitions
├── packages/
│   └── elbe-demo-pkg-hello/           # Debian packaging for the hello app
├── sources/
│   └── elbe-demo-app-hello/           # hello app source code
├── tools/
│   ├── elbe-devcontainers/            # this repository
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   └── entrypoint.sh
│   ├── elbe-ui/                       # web UI (FastAPI)
│   └── elbe-demo-apt-repository/      # local APT repo tooling
└── elbe-demo-manifest/
    └── default.xml                    # Google Repo manifest
```

## License

See the [LICENSE](LICENSE) file.
