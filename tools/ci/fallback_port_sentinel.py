#!/usr/bin/env python3
"""Fallback-port sentinel for the CLI test suite.

When a Wheels CLI command cannot find this project's own server it may fall
back to probing common dev ports (8080, 60000, 3000, 8500). Commands that
change state, run code or carry the reload password must never do that, and
no spec should ever reach a server it did not start. The sentinel makes a
regression visible: it listens on the fallback ports for the length of a test
run and records every connection, so the run can fail if anything contacted
them.

    fallback_port_sentinel.py serve --log FILE --ports 8080,60000,3000,8500 [--ready-file FILE]
    fallback_port_sentinel.py check --log FILE

`serve` binds every port (dual-stack where available, so `localhost`
resolving to ::1 or 127.0.0.1 both land here), writes the bound ports to
--ready-file once listening, answers each request with a 503 and appends one
JSON line per connection to --log. A port that is already taken is an error:
a sentinel that cannot guard a port must not report it clean.

`check` prints every recorded contact and exits 1 if there were any, 0 if the
log is empty or missing, 2 on a malformed log.
"""
import argparse
import json
import os
import shutil
import signal
import socket
import sys
import threading
import time

RESPONSE = (
    b"HTTP/1.1 503 Wheels fallback-port sentinel\r\n"
    b"Content-Type: text/plain\r\n"
    b"Content-Length: 58\r\n"
    b"Connection: close\r\n\r\n"
    b"This port is guarded by the Wheels fallback-port sentinel.\n"
)


def bind(port):
    """Listen on `port` on every local address. Raises OSError if taken."""
    try:
        sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        address = ("::", port)
    except (OSError, AttributeError):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        address = ("0.0.0.0", port)
    # No SO_REUSEADDR: binding must fail if anything else holds the port.
    sock.bind(address)
    sock.listen(16)
    return sock


class Sentinel:
    """Guards ports and logs contacts.

    Every connection is logged the moment it is accepted, before anything is
    read from it, so a client that connects and stays silent (or is still
    mid-request when the run ends) is never lost. The request line, when one
    arrives, is logged as a second entry with the same id. stop() also takes
    any connection still waiting in the listen backlog and gives in-flight
    handlers time to log their request line.
    """

    def __init__(self, log_path):
        self.log_path = log_path
        self.lock = threading.Lock()
        self.listeners = []
        self.handlers = []
        self.next_id = 0

    def write(self, entry):
        now = time.time()
        # Milliseconds, so a contact can be matched to the spec that ran then.
        entry["time"] = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(now)) + ".%03dZ" % int((now % 1) * 1000)
        with self.lock, open(self.log_path, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(entry) + "\n")
            fh.flush()

    def accepted(self, conn, port, addr, spawn=True):
        with self.lock:
            self.next_id += 1
            contact_id = self.next_id
        peer = str(addr[0]) if addr else "?"
        self.write({"id": contact_id, "event": "connect", "port": port, "peer": peer})
        if spawn:
            peer_port = addr[1] if addr and len(addr) > 1 else 0
            thread = threading.Thread(target=self.handle, args=(conn, contact_id, port, peer_port), daemon=True)
            with self.lock:
                self.handlers.append(thread)
            thread.start()
        else:
            try:
                conn.close()
            except OSError:
                pass

    def handle(self, conn, contact_id, port=0, peer_port=0):
        # Name the connecting process while the connection is still open, so a
        # local run on a shared machine can tell its own contacts from another
        # program's. Best effort: omitted when the OS will not say.
        client, chain = client_process(port, peer_port)
        if client:
            self.write({"id": contact_id, "event": "client", "client": client, "chain": chain})
        try:
            conn.settimeout(2.0)
            data = b""
            while b"\r\n" not in data and len(data) < 8192:
                chunk = conn.recv(1024)
                if not chunk:
                    break
                data += chunk
            first_line = data.split(b"\r\n", 1)[0].decode("latin-1").strip()
            if first_line:
                self.write({"id": contact_id, "event": "request", "request": first_line})
                conn.sendall(RESPONSE)
        except OSError:
            pass
        finally:
            try:
                conn.close()
            except OSError:
                pass

    def accept_loop(self, sock, port):
        while True:
            try:
                conn, addr = sock.accept()
            except OSError:
                return
            self.accepted(conn, port, addr)

    def start(self, ports):
        bound = []
        for port in ports:
            try:
                sock = bind(port)
            except OSError as err:
                self.stop()
                raise SystemExit(
                    "fallback-port sentinel: cannot bind port %d (%s). Something else is using it, "
                    "so the sentinel cannot guard it; free the port or run without the sentinel." % (port, err)
                )
            self.listeners.append((sock, sock.getsockname()[1]))
            bound.append(sock.getsockname()[1])
            threading.Thread(target=self.accept_loop, args=(sock, bound[-1]), daemon=True).start()
        return bound

    def stop(self, drain_seconds=2.5):
        for sock, port in self.listeners:
            # Connections the kernel completed but nobody accept()ed yet.
            try:
                sock.setblocking(False)
                while True:
                    conn, addr = sock.accept()
                    self.accepted(conn, port, addr, spawn=False)
            except OSError:
                pass
            try:
                sock.close()
            except OSError:
                pass
        self.listeners = []
        deadline = time.time() + drain_seconds
        with self.lock:
            handlers = list(self.handlers)
        for thread in handlers:
            thread.join(max(0.0, deadline - time.time()))


def parent_chain(pid):
    """[pid, parent, grandparent, ...] up to init, best effort."""
    chain = []
    current = str(pid)
    while current and current not in chain and current not in ("0", "1") and len(chain) < 64:
        chain.append(current)
        parent = ""
        try:
            if os.path.exists("/proc/%s/stat" % current):
                with open("/proc/%s/stat" % current) as fh:
                    parent = fh.read().rsplit(")", 1)[1].split()[1]
            else:
                import subprocess
                parent = subprocess.run(["ps", "-o", "ppid=", "-p", current],
                                        capture_output=True, text=True, timeout=5).stdout.strip()
        except (OSError, IndexError, Exception):
            parent = ""
        current = parent
    return chain


def client_process(server_port, peer_port):
    """('pid N (command)', parent chain) of the client end of a connection."""
    name, pid = _client_process(server_port, peer_port)
    return (name, parent_chain(pid)) if pid else ("", [])


def _client_process(server_port, peer_port):
    if not peer_port:
        return "", ""
    own = os.getpid()
    try:
        if os.path.exists("/proc/net/tcp"):
            inodes = set()
            for table in ("/proc/net/tcp", "/proc/net/tcp6"):
                if not os.path.exists(table):
                    continue
                with open(table) as fh:
                    for line in list(fh)[1:]:
                        cols = line.split()
                        if len(cols) > 9 and int(cols[1].split(":")[1], 16) == peer_port \
                                and int(cols[2].split(":")[1], 16) == server_port:
                            inodes.add("socket:[%s]" % cols[9])
            for pid in filter(str.isdigit, os.listdir("/proc")):
                if int(pid) == own:
                    continue
                try:
                    for fd in os.listdir("/proc/%s/fd" % pid):
                        if os.readlink("/proc/%s/fd/%s" % (pid, fd)) in inodes:
                            with open("/proc/%s/comm" % pid) as fh:
                                return "pid %s (%s)" % (pid, fh.read().strip()), pid
                except OSError:
                    continue
            return "", ""
        lsof = shutil.which("lsof") or ("/usr/sbin/lsof" if os.path.exists("/usr/sbin/lsof") else "")
        if not lsof:
            return "", ""
        import subprocess
        out = subprocess.run([lsof, "-nP", "-iTCP:%d" % peer_port, "-sTCP:ESTABLISHED", "-Fpc"],
                             capture_output=True, text=True, timeout=5).stdout
        pid = ""
        for line in out.splitlines():
            if line.startswith("p"):
                pid = line[1:]
            elif line.startswith("c") and pid and int(pid) != own:
                return "pid %s (%s)" % (pid, line[1:]), pid
    except (OSError, ValueError, Exception):
        return "", ""
    return "", ""


def read_log(log_path):
    """Return one record per contact, request line attached when one arrived.

    Raises ValueError on a malformed line.
    """
    if not os.path.exists(log_path):
        return []
    contacts = {}
    order = []
    with open(log_path, encoding="utf-8") as fh:
        for number, line in enumerate(fh, 1):
            if not line.strip():
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                raise ValueError("line %d is not JSON: %r" % (number, line.strip()))
            if not isinstance(entry, dict) or "id" not in entry:
                raise ValueError("line %d has no contact id: %r" % (number, line.strip()))
            contact = contacts.get(entry["id"])
            if contact is None:
                contact = {"request": "(connected without sending a request)"}
                contacts[entry["id"]] = contact
                order.append(entry["id"])
            if entry.get("event") == "request":
                contact["request"] = entry.get("request", "")
            elif entry.get("event") == "client":
                contact["client"] = entry.get("client", "")
                contact["chain"] = [str(p) for p in entry.get("chain", [])]
            else:
                contact.update({k: entry.get(k) for k in ("time", "port", "peer")})
    return [contacts[i] for i in order]


def parse_ports(text):
    ports = []
    for item in text.split(","):
        item = item.strip()
        if item:
            ports.append(int(item))
    return ports


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    serve = sub.add_parser("serve")
    serve.add_argument("--log", required=True)
    serve.add_argument("--ports", required=True, help="comma-separated ports to guard")
    serve.add_argument("--ready-file", help="written with the bound ports once listening")
    check = sub.add_parser("check")
    check.add_argument("--log", required=True)
    check.add_argument("--run-pid", action="append", default=[],
                       help="pid of a process belonging to this run (repeatable); a contact attributed to "
                            "another pid is reported as 'not this run' and does not fail the check")
    args = parser.parse_args(argv)

    if args.command == "check":
        try:
            entries = read_log(args.log)
        except ValueError as err:
            print("fallback-port sentinel: malformed log %s: %s" % (args.log, err))
            return 2
        if not entries:
            print("Fallback-port sentinel: nothing contacted the fallback ports.")
            return 0
        run_pids = {str(p) for p in args.run_pid}

        # A contact is only excused when it is PROVEN to come from a process
        # outside this run: attributed, with no run pid anywhere in its parent
        # chain (so a child the run spawned still counts as the run's). An
        # unattributed contact counts against the run.
        foreign = [e for e in entries
                   if run_pids and e.get("chain") and not run_pids.intersection(e["chain"])]
        ours = [e for e in entries if e not in foreign]

        def show(entry, note=""):
            print("  %s  :%s  from %s%s  %s%s" % (
                entry.get("time"), entry.get("port"), entry.get("peer"),
                " " + entry["client"] if entry.get("client") else "", entry.get("request"), note))

        for entry in foreign:
            show(entry, "  [contact from %s, not this run]" % entry["client"])
        if not ours:
            print("Fallback-port sentinel: nothing in this run contacted the fallback ports "
                  "(%d contact(s) from other processes, listed above)." % len(foreign))
            return 0
        print("Fallback-port sentinel: %d connection(s) reached a fallback port. "
              "Something in this run tried to use a server it does not own:" % len(ours))
        for entry in ours:
            show(entry)
        return 1

    ports = parse_ports(args.ports)
    if not ports:
        print("fallback-port sentinel: no ports to guard")
        return 2
    sentinel = Sentinel(args.log)
    bound = sentinel.start(ports)
    if args.ready_file:
        tmp = args.ready_file + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(",".join(str(p) for p in bound) + "\n")
        os.replace(tmp, args.ready_file)
    print("Fallback-port sentinel guarding: %s" % ", ".join(str(p) for p in bound), flush=True)

    stop = threading.Event()
    signal.signal(signal.SIGTERM, lambda *_: stop.set())
    signal.signal(signal.SIGINT, lambda *_: stop.set())
    while not stop.wait(0.5):
        pass
    sentinel.stop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
