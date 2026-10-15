# 🚀 FreeBSD Server Initialization

Automated initialization toolkit for **FreeBSD 14.x and 15.x** servers. This project downloads and executes a collection of installation scripts to prepare a new server with development dependencies, bhyve virtualization, network testing utilities, and optional CPU + RAM stress testing.

## ✨ Features

- 📥 **Automatic Script Downloads** — Downloads all four installation scripts from GitHub Gists.
- 📦 **Default Dependencies** — Installs the required development and system administration tools.
- 🖥️ **Bhyve Virtualization** — Installs and configures `vm-bhyve` and its dependencies.
- 🌐 **Network Testing** — Installs Ookla Speedtest CLI and iperf3.
- 🔥 **CPU + RAM Stress Testing** — Runs an optional two-hour stress test with configurable CPU and memory settings.
- 🛑 **Failure Handling** — Stops the initialization process when a required installation stage fails.
- 📝 **Logging** — Records initialization output for troubleshooting.
- ✋ **Interactive Approval** — Requires administrator confirmation before starting the stress test.

## 📋 Requirements

- FreeBSD 14.x or 15.x
- Root privileges
- Internet connectivity
- A working FreeBSD package repository
- Sufficient disk space for installed packages and downloaded scripts
- Sufficient available RAM and swap before running the stress test

> **Warning:** The stress test can heavily load the CPU and allocate significant amounts of RAM. Review the configuration before running it on a production server.

## 📥 Installation

### 1. Download the Master Script

Save the master script as `freebsd-server-init.sh` on the target server.

### 2. Make the Script Executable

```sh
chmod +x freebsd-server-init.sh
```

### 3. Run the Initialization

Run as root:

```sh
./freebsd-server-init.sh
```

Alternatively, if Bash is installed:

```sh
bash freebsd-server-init.sh
```

If you are logged in as root, `sudo` is not necessary.

## 🔄 Initialization Workflow

The master script executes the following stages in order:

| Step | Stage | Description |
|---|---|---|
| 1 | Download Scripts | Downloads all four Gist scripts before installation begins. |
| 2 | Default Dependency | Installs the default development and system administration packages. |
| 3 | Bhyve | Installs and configures bhyve virtualization tools. |
| 4 | Network Testing | Installs Ookla Speedtest CLI and iperf3. |
| 5 | Administrator Approval | Waits for approval before running the stress test. |
| 6 | CPU + RAM Stress Test | Runs the configured stress test if approved. |

If a required download or installation stage fails, the master script stops instead of continuing to the next stage.

## 📦 Source Scripts

The initialization process uses the following GitHub Gists:

| Component | Description | Source |
|---|---|---|
| Default Dependency | Default development and system dependencies | [View Gist](https://gist.github.com/Christo-heal/264516bae501b1ad0fdca94265255c7b) |
| Bhyve | Virtualization installation and configuration | [View Gist](https://gist.github.com/Christo-heal/89bfc386eabc34e87970882df262684f) |
| Speedtest | Ookla Speedtest CLI and iperf3 | [View Gist](https://gist.github.com/Christo-heal/2226c22a323c8c12d6d9572772aae42c) |
| Stress Test | CPU and RAM stress testing | [View Gist](https://gist.github.com/Christo-heal/32aad302d07bc46b6af049451978e994) |

## 🔥 Stress Test Configuration

The default stress test configuration is:

| Parameter | Default Value |
|---|---|
| Duration | 2 hours |
| CPU workers | Automatically detected CPU count |
| RAM workers | 4 |
| RAM per worker | 6 GiB |
| Approximate RAM allocation target | Up to 24 GiB |
| Disk benchmark | Disabled |

The memory allocation target is not a guarantee of actual memory usage. Actual consumption depends on system conditions and the stress-ng workload.

### Approval Options

When initialization reaches the final stage, the script presents the following options:

- **`1` — Continue:** Proceed to the stress test.
- **`2` — Edit:** Open the stress test script in `vi` to adjust CPU and RAM settings.

After editing, the administrator can run the test, reopen the editor, or cancel the stress test.

The master script also requests an explicit `YES` confirmation before starting the test.

### Recommended Safety Checks

Before running the stress test:

```sh
sysctl hw.ncpu hw.physmem
vmstat -s
swapinfo -h
```

Check the available memory and swap capacity, especially on servers hosting virtual machines or other production workloads.

## 📂 Directory Structure

The master script uses the following directories:

```text
/root/server-init/
└── scripts/
    ├── default-dependency.sh
    ├── install-vm-bhyve.sh
    ├── install-speedtest.sh
    └── stress-test.sh

/var/log/server-init/
└── init-YYYYMMDD-HHMMSS.log
```

The downloaded scripts are stored locally so the administrator can inspect or edit them before execution.

## 📊 Monitoring and Logs

The master initialization log is stored in:

```text
/var/log/server-init/
```

To view the latest initialization logs:

```sh
ls -lt /var/log/server-init/
```

To inspect a specific log:

```sh
less /var/log/server-init/init-YYYYMMDD-HHMMSS.log
```

Replace the filename with the actual log name.

For stress test logs, refer to the stress test script's own output paths.

## 🛠️ Troubleshooting

### Package Installation Failure

Check the package repository and connectivity:

```sh
pkg update
pkg -vv
```

Resolve repository issues before rerunning the initialization.

### Script Download Failure

Verify network access to GitHub:

```sh
fetch -o /dev/null https://gist.github.com/
```

Ensure the Gist URLs are accessible and the scripts are available.

### Bhyve Configuration

After installation, inspect the virtualization configuration:

```sh
vm version
vm datastore list
vm switch list
vm list
```

Verify the virtual switch and datastore configuration before creating virtual machines.

### Speedtest and iperf3 Verification

```sh
speedtest --version
iperf3 --version
```

For an iperf3 throughput test, start the server on one machine:

```sh
iperf3 -s
```

Then run the client from another machine:

```sh
iperf3 -c SERVER_IP
```

To test in the reverse direction:

```sh
iperf3 -c SERVER_IP -R
```

Replace `SERVER_IP` with the actual server address.

## ⚠️ Important Notes

- Run the master script with the required privileges.
- Review downloaded scripts before executing them on production systems.
- The master script assumes each Gist's raw URL returns the intended shell script.
- Ensure the execution shell supports the script's features, including Bash process substitution if used for logging.
- The bhyve stage does not automatically guarantee that a suitable virtual switch or datastore exists.
- The stress test is optional and should be performed only after reviewing the server's resource capacity.
- Installing packages or upgrading dependencies may affect existing system configurations.

## 📄 License

Choose and add an appropriate license before distributing or publishing this project for public use.

---

**FreeBSD Server Initialization**  
*Automate the setup. Verify the configuration. Test the performance.*
