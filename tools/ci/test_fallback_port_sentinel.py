"""Tests for tools/ci/fallback_port_sentinel.py. Run: python3 tools/ci/test_fallback_port_sentinel.py"""
import contextlib
import importlib.util
import io
import os
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("fallback_port_sentinel", os.path.join(HERE, "fallback_port_sentinel.py"))
fps = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(fps)


def check(log_path):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = fps.main(["check", "--log", log_path])
    return code, out.getvalue()


def wait_for_entries(log_path, count, timeout=5.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if len(fps.read_log(log_path)) >= count:
            return
        time.sleep(0.05)


class SentinelTests(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.log = os.path.join(self.tmp.name, "sentinel.log")
        self.sentinel = fps.Sentinel(self.log)

    def tearDown(self):
        self.sentinel.stop()
        self.tmp.cleanup()

    def test_a_clean_run_passes(self):
        self.sentinel.start([0])
        self.assertEqual(check(self.log)[0], 0)

    def test_records_an_http_request_and_fails_the_check(self):
        port = self.sentinel.start([0])[0]
        with socket.create_connection(("localhost", port), timeout=5) as conn:
            conn.sendall(b"GET /wheels/cli?command=info HTTP/1.1\r\nHost: localhost\r\n\r\n")
            reply = conn.recv(1024)
        self.assertIn(b"503", reply)
        wait_for_entries(self.log, 1)
        code, out = check(self.log)
        self.assertEqual(code, 1)
        self.assertIn("GET /wheels/cli?command=info", out)
        self.assertIn(":%d" % port, out)

    def test_records_a_connect_only_port_probe(self):
        port = self.sentinel.start([0])[0]
        socket.create_connection(("localhost", port), timeout=5).close()
        wait_for_entries(self.log, 1)
        code, out = check(self.log)
        self.assertEqual(code, 1)
        self.assertIn("connected without sending a request", out)

    def test_refuses_a_port_it_cannot_bind(self):
        holder = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        holder.bind(("127.0.0.1", 0))
        holder.listen(1)
        try:
            with self.assertRaises(SystemExit) as raised:
                self.sentinel.start([holder.getsockname()[1]])
            self.assertIn("cannot bind port", str(raised.exception))
        finally:
            holder.close()

    def test_a_silent_connection_still_open_at_shutdown_is_recorded(self):
        port = self.sentinel.start([0])[0]
        conn = socket.create_connection(("localhost", port), timeout=5)
        try:
            time.sleep(0.15)
            self.sentinel.stop(drain_seconds=0.1)
        finally:
            conn.close()
        code, out = check(self.log)
        self.assertEqual(code, 1)
        self.assertIn("connected without sending a request", out)

    def test_serve_records_a_held_connection_when_terminated_like_the_harness(self):
        # rev1-r2 repro: connect, hold the socket open, SIGTERM + wait the
        # serve process exactly as tools/test-cli-local.sh does, then check.
        ready = os.path.join(self.tmp.name, "ready")
        proc = subprocess.Popen(
            [sys.executable, os.path.join(HERE, "fallback_port_sentinel.py"), "serve",
             "--log", self.log, "--ports", "0", "--ready-file", ready],
            stdout=subprocess.DEVNULL,
        )
        try:
            deadline = time.time() + 10
            while not os.path.exists(ready) and time.time() < deadline:
                time.sleep(0.05)
            port = int(open(ready).read().strip())
            conn = socket.create_connection(("localhost", port), timeout=5)
            time.sleep(0.15)
            proc.send_signal(signal.SIGTERM)
            proc.wait(timeout=10)
            conn.close()
        finally:
            if proc.poll() is None:
                proc.kill()
        code, out = check(self.log)
        self.assertEqual(code, 1)
        self.assertIn(":%d" % port, out)

    def run_check(self, *run_pids):
        out = io.StringIO()
        argv = ["check", "--log", self.log]
        for pid in run_pids:
            argv += ["--run-pid", str(pid)]
        with contextlib.redirect_stdout(out):
            code = fps.main(argv)
        return code, out.getvalue()

    def test_names_the_connecting_process_and_its_parent_chain(self):
        port = self.sentinel.start([0])[0]
        holder = subprocess.Popen([sys.executable, "-c",
                                   "import socket,time;s=socket.create_connection(('127.0.0.1',%d));time.sleep(3)" % port])
        try:
            wait_for_entries(self.log, 1)
            deadline = time.time() + 5
            while time.time() < deadline and not fps.read_log(self.log)[0].get("client"):
                time.sleep(0.05)
            contact = fps.read_log(self.log)[0]
            self.assertIn("pid %d" % holder.pid, contact.get("client", ""))
            self.assertIn(str(os.getpid()), contact.get("chain", []))
        finally:
            holder.kill()

    def test_a_contact_proven_to_come_from_another_process_is_not_this_run(self):
        with open(self.log, "w") as fh:
            fh.write('{"id": 1, "event": "connect", "port": 8080, "peer": "::1", "time": "t"}\n')
            fh.write('{"id": 1, "event": "client", "client": "pid 4242 (curl)", "chain": ["4242", "4000"], "time": "t"}\n')
        code, out = self.run_check(9999)
        self.assertEqual(code, 0)
        self.assertIn("not this run", out)

    def test_a_contact_from_the_run_or_its_children_fails(self):
        with open(self.log, "w") as fh:
            fh.write('{"id": 1, "event": "connect", "port": 8080, "peer": "::1", "time": "t"}\n')
            fh.write('{"id": 1, "event": "client", "client": "pid 4242 (wheels)", "chain": ["4242", "9999"], "time": "t"}\n')
        self.assertEqual(self.run_check(9999)[0], 1)

    def test_an_unattributed_contact_fails_even_with_run_pids(self):
        with open(self.log, "w") as fh:
            fh.write('{"id": 1, "event": "connect", "port": 8080, "peer": "::1", "time": "t"}\n')
        self.assertEqual(self.run_check(9999)[0], 1)

    def test_missing_log_is_clean_and_malformed_log_is_an_error(self):
        self.assertEqual(check(os.path.join(self.tmp.name, "absent.log"))[0], 0)
        with open(self.log, "w") as fh:
            fh.write("not json\n")
        self.assertEqual(check(self.log)[0], 2)


if __name__ == "__main__":
    unittest.main()
