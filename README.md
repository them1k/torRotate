# torRotate

A script for rotating IP addresses through Tor, designed for OPSEC operations.  
This script try to **fix the limitations** of tools like `tornet`, providing an efficient and controlled way to automatically change your IP address without breaking your sessions.

---

## The problem with tornet

In my opinion, the problem with `tornet` is that restarting Tor every few seconds **is not ideal** because:

- It breaks persistent TCP connections (losing sessions or exposing your real IP)
- It is much slower to change IPs
- It can burn Tor circuits and overuse entry/exit nodes
- It creates unnatural traffic patterns, increasing detection risk

I think for a **professional OPSEC operation**, you should use the `SIGNAL NEWNYM` command via **Tor's ControlPort**,  
**not** restart Tor processes all the time :)

---

## What this script does

It's very simple:

- Sends a `SIGNAL NEWNYM` request every set interval to change the Tor circuit.
- Verifies that the public IP has actually changed.
- Logs each new IP along with a timestamp to a file (`/var/log/tor-ip-rotation.log` by default).
- Before each rotation, it checks:
  - That Tor is running.
  - That the SOCKS5 proxy port (9050) is open.
- If Tor is not active or available, **the script exits automatically**.

---

## Installation and setup

### 1. Install Tor

```bash
sudo apt update
sudo apt install tor
```

**Important**: if you are using Debian or Ubuntu, make sure to activate the correct instance.

Enable and start `tor@default` (and **not** the dummy `tor.service`):

```bash
sudo systemctl enable tor@default
sudo systemctl start tor@default
sudo systemctl status tor@default
```

You should see `Active: active (running)` and `Main PID: tor`.

---

### 2. Configure Tor to allow control

Edit the Tor configuration file:

```bash
sudo nano /etc/tor/torrc
```

Make sure it includes (at least):

```bash
RunAsDaemon 1
SocksPort 9050
ControlPort 9051
CookieAuthentication 0
```

Save and reload Tor:

```bash
sudo systemctl restart tor@default
```

---

### 3. Install torsocks

```bash
sudo apt install torsocks
```

**Test if it's working:**

```bash
torsocks curl https://check.torproject.org
```

If everything is fine, you should see:

```
Congratulations. This browser is configured to use Tor.
```

---

### 4. Download the script

Clone this repository:

```bash
git clone https://github.com/them1k/torRotate.git
cd torRotate
```

Make it executable:

```bash
chmod +x torRotate.sh
```

---

### 5. Run the script

```bash
sudo ./torRotate.sh
```

> It is recommended to run it as root to allow writing to `/var/log/tor-ip-rotation.log`.

Each IP change will be automatically logged.

---

## Example of log output

```
2025-04-04 10:33:15 - 185.33.152.11
2025-04-04 10:33:25 - 185.93.152.42
2025-04-04 10:33:35 - 185.13.153.87
```

---

## Notes

- If you want to change the log file path or the rotation interval, just edit the variables at the top of the script.
- For an even higher OPSEC environment, you can route your entire system through Tor, but this script is mainly designed to work with CLI tools like `curl`, `feroxbuster`, `sqlmap`, etc., using `torsocks`.

---

## Credits

Developed to improve OPSEC operations where constant IP rotation is required without breaking TCP sessions or exposing unnatural traffic patterns.
