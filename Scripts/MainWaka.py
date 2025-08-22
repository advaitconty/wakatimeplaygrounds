# main wakatime script

import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import base64
import json
import sys
import threading
import time
from io import StringIO
import datetime
import requests
import platform

_buffer = StringIO()
_stop_flag = False
_thread = None

class StreamCatcher:
    def write(self, text):
        _buffer.write(text)

    def flush(self):
        pass

sys_is_main = (__name__ == "__main__")
if not sys_is_main:
    sys.stdout = StreamCatcher()

def build_ua(client="wakatime-playgrounds", version="0.1", runtime=None):
    runtime = f"python/{platform.python_version()}"
    os_ = f"{platform.system()}/{platform.release()}"
    ua = f"{client}/{version} ({runtime}; {os_})"
    return ua[:200]

class HeartbeatHandler(FileSystemEventHandler):
    def __init__(self, tracker, directory, interval):
        self.tracker = tracker
        self.directory = directory
        self.interval = interval

    def on_any_event(self, event):
        if event.is_directory:
            return
        data = {
            "entity": event.src_path,
            "type": "file",
            "category": "coding",
            "timestamp": time.time(),
            "is_write": event.event_type in ["modified", "created"],
            "project": os.path.basename(self.directory),
            "editor": "Wakatime Playgrounds",
            "branch": "master"
        }
        self.tracker.send_heartbeat(data)

class Tracker():
    def __init__(self, debugMode, api_url, api_key, interval):
        self.debugMode = debugMode
        self.running = False
        
        self.api_url = api_url
        self.api_key = api_key
        self.interval = interval

        self._thread = None
        self._stop_flag = threading.Event()

        self._session = requests.Session()
        self._session.headers.update({"User-Agent": build_ua()})

        encoded_key = base64.b64encode(self.api_key.encode()).decode()
        self._session.headers.update({"Authorization": f"Basic {encoded_key}"})

        if self.debugMode:
            print("DEBUG: Tracker initialised")

    def worker(self):
        pass

    def start(self, directory, interval):
        if self._thread is None or not self._thread.is_alive():
            self._stop_flag.clear()
            self._thread = threading.Thread(target=self.worker, daemon=True)
            self._thread.start()
            self.running = True

            self._event_handler = HeartbeatHandler(self, directory, interval)
            self._observer = Observer()
            self._observer.schedule(self._event_handler, directory, recursive=True)
            self._observer.daemon = True
            self._observer.start()

            if self.debugMode:
                print("DEBUG: Tracker started")
                print(f"Watching {directory} for changes")

    def stop(self):
        self._stop_flag.set()
        self.running = False

        if hasattr(self, "_observer"):
            self._observer.stop()
            self._observer.join()
            if self.debugMode:
                print("DEBUG: Observer stopped")

        if self.debugMode:
            print("DEBUG: Tracker stopped")

    def send_heartbeat(self, data):
        endpoint = f"{self.api_url}/users/current/heartbeats"
        payload = data
        if self.debugMode:
            print(f"DEBUG: Sending heartbeat to {endpoint} with data: {json.dumps(payload)}")
    
        try:
            response = self._session.post(endpoint, json=payload, timeout=10)
            response.raise_for_status()
            if self.debugMode:
                print("DEBUG: {} Response received!".format(response.status_code))
                print(f"JSON: {response.json()}")

            return response.json()

        except requests.exceptions.RequestException as e:
            if self.debugMode:
                print(f"DEBUG: Error occurred: {e}")
                print(response.json())
            
            return {"error": str(e)}

    @staticmethod
    def get_logs():
        return _buffer.getvalue()

# i'm lazy for this, AI created this for tests
if __name__ == "__main__":
    api_url = "https://hackatime.hackclub.com/api/hackatime/v1"
    api_key = "7a73025b-4cc5-4a65-b823-ec4c49d085f0"
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
