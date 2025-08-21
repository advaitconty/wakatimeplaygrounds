# main wakatime script

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

sys.stdout = StreamCatcher()

def build_ua(client="wakatime-playgrounds", version="0.1", runtime=None):
    runtime = f"python/{platform.python_version()}"
    os_ = f"{platform.system()}/{platform.release()}"
    ua = f"{client}/{version} ({runtime}; {os_})"
    return ua[:200]

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
        
        if self.debugMode:
            print("DEBUG: Tracker initialised")

    def worker(self):
        while not self._stop_flag.is_set():
            time.sleep(1)
            if self.debugMode:
                print("DEBUG: Tracker is running")
                print("DEBUG: Current time is {}".format(datetime.datetime.now()))

    def start(self):
        if self._thread is None or not self._thread.is_alive():
            self._stop_flag.clear()
            self._thread = threading.Thread(target=self.worker, daemon=True)
            self._thread.start()
            self.running = True
            if self.debugMode:
                print("DEBUG: Tracker started")

    def stop(self):
        self._stop_flag.set()
        self.running = False
        if self.debugMode:
            print("DEBUG: Tracker stopped")

    def _send_heartbeat(self, payload):
        try:
            resp = self._session.post(self.api_url, json=payload

    @staticmethod
    def get_logs():
        return _buffer.getvalue()
