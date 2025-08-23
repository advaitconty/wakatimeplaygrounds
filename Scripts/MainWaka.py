import os
import base64
import json
import sys
import threading
import time
import ssl
from io import StringIO
from urllib import request, error
import platform

_buffer = StringIO()

class StreamCatcher:
    def write(self, text): _buffer.write(text)
    def flush(self): pass

if __name__ != "__main__":
    sys.stdout = StreamCatcher()

def build_ua(client="wakatime-playgrounds", version="0.1"):
    runtime = f"python/{platform.python_version()}"
    os_ = f"{platform.system()}/{platform.release()}"
    return f"{client}/{version} ({runtime}; {os_})"[:200]

LANG_MAP = {
    "py":"python",
    "js":"javascript",
    "html":"html",
    "css":"css",
    "java":"java",
    "cpp":"cpp",
    "c":"c",
    "go":"go",
    "rb":"ruby",
    "php":"php",
    "swift":"swift",
    "ts":"typescript",
    "md":"markdown",
    "swiftpm":"swift",
    "sh":"bash",
    "json":"json",
    "yaml":"yaml",
    "toml":"toml",
    "ini":"ini",
    "txt":"text",
    "xml":"xml",
    "csv":"csv",
    "tsv":"tsv",
    "log":"text",
    "mdx":"markdown",
}

def lang_for(path):
    _, ext = os.path.splitext(path)
    return LANG_MAP.get(ext[1:].lower(), "unknown")

class Tracker:
    def __init__(self, debugMode, api_url, api_key, interval):
        self.debugMode = debugMode
        self.running = False
        self.api_url = api_url
        self.api_key = api_key
        self.interval = max(1, int(interval) if interval else 5)

        self._thread = None
        self._stop_flag = threading.Event()

        enc = base64.b64encode(self.api_key.encode()).decode()
        self._headers = {
            "User-Agent": build_ua(),
            "Authorization": f"Basic {enc}",
            "Content-Type": "application/json",
        }

        if self.debugMode: print("DEBUG: Tracker initialised")

    def _poll_once(self, directory, seen):
        try:
            current = {}
            for root, dirs, files in os.walk(directory):
                # skip hidden dirs (start with ".")
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                for name in files:
                    if name.startswith("."):
                        continue
                    p = os.path.join(root, name)
                    try:
                        mtime = os.path.getmtime(p)
                        # store relative path from base dir
                        rel = os.path.relpath(p, directory)
                        current[rel] = mtime
                    except PermissionError:
                        if self.debugMode:
                            print(f"DEBUG: Skipping (perm): {p}")
                    except FileNotFoundError:
                        continue
        except PermissionError:
            if self.debugMode:
                print("DEBUG: No permission to list directory; will retry")
            return seen

        added = set(current.keys()) - set(seen.keys())
        removed = set(seen.keys()) - set(current.keys())
        modified = {
            rel for rel, mtime in current.items()
            if rel in seen and mtime > seen[rel]
        }

        now = time.time()
        for rel in added:
            path = os.path.join(directory, rel)
            self._heartbeat(path, "created", now, directory)
        for rel in removed:
            path = os.path.join(directory, rel)
            self._heartbeat(path, "deleted", now, directory)
        for rel in modified:
            path = os.path.join(directory, rel)
            self._heartbeat(path, "modified", now, directory)

        return current


    def worker(self, directory, interval):
        try:
            seen = {}
            try:
                for root, dirs, files in os.walk(directory):
                    dirs[:] = [d for d in dirs if not d.startswith(".")]
                    for name in files:
                        if not name.startswith("."):
                            p = os.path.join(root, name)
                            try:
                                mtime = os.path.getmtime(p)
                                rel = os.path.relpath(p, directory)
                                seen[rel] = mtime
                            except (PermissionError, FileNotFoundError):
                                continue
            except Exception as e:
                if self.debugMode:
                    print(f"DEBUG: initial walk failed: {e}")
            while not self._stop_flag.is_set():
                time.sleep(self.interval)
                seen = self._poll_once(directory, seen)
        finally:
            if self.debugMode:
                print("DEBUG: worker exit")

    def start(self, directory, interval=None):
        if self._thread is None or not self._thread.is_alive():
            self._stop_flag.clear()
            self._thread = threading.Thread(
                target=self.worker, args=(directory, self.interval), daemon=True
            )
            self._thread.start()
            self.running = True
            if self.debugMode:
                print("DEBUG: Tracker started")
                print(f"Watching (polling) {directory}")

    def stop(self):
        self._stop_flag.set()
        self.running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=2)
        if self.debugMode: print("DEBUG: Tracker stopped")

    def _heartbeat(self, entity, evt, now, directory):
        payload = {
            "entity": entity,
            "type": "file",
            "category": "coding",
            "time": now,
            "is_write": evt in ("created", "modified"),
            "project": os.path.basename(directory),
            "language": lang_for(entity),
            "editor": "Wakatime Playgrounds",
            "branch": "main",
            "operating_system": platform.system(),
            "machine": platform.node(),
            "event": evt,
        }
        self.send_heartbeat(payload)

    def send_heartbeat(self, data):
        endpoint = f"{self.api_url}/users/current/heartbeats"
        if self.debugMode:
            print(f"DEBUG: Sending heartbeat to {endpoint} with data: {json.dumps(data)}")
        
        req_data = json.dumps(data).encode('utf-8')
        req = request.Request(endpoint, data=req_data, headers=self._headers, method='POST')

        try:
            # Create an SSL context that does not verify certificates
            ssl_context = ssl._create_unverified_context()
            with request.urlopen(req, timeout=10, context=ssl_context) as response:
                if self.debugMode:
                    print(f"DEBUG: {response.status} Response received!")
                
                content_type = response.headers.get('content-type', '')
                if content_type.startswith("application/json"):
                    body = response.read().decode('utf-8')
                    return json.loads(body)
                return {}
        except error.HTTPError as e:
            if self.debugMode: print(f"DEBUG: HTTP Error occurred: {e.code} {e.reason}")
            return {"error": str(e)}
        except error.URLError as e:
            if self.debugMode: print(f"DEBUG: URL Error occurred: {e.reason}")
            return {"error": str(e)}
        except Exception as e:
            if self.debugMode: print(f"DEBUG: An unexpected error occurred: {e}")
            return {"error": str(e)}

    @staticmethod
    def get_logs(): 
        return _buffer.getvalue()

# i'm lazy for this, AI created this for tests
if __name__ == "__main__":
    api_url = "https://hackatime.hackclub.com/api/hackatime/v1"
    api_key = "oops"
    interval = 30
    debug = True

    directory = "/Users/mcontrac/Library/Mobile Documents/com~apple~CloudDocs/advait/Conty.LAB/test project for wakatime playgrounds code"

    tracker = Tracker(debug, api_url, api_key, interval)
    tracker.start(directory, interval)

    print(f"Tracker running. Modify files in {directory} to trigger heartbeats. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopping tracker...")
        tracker.stop()
        print("Logs:")
        print(tracker.get_logs())
