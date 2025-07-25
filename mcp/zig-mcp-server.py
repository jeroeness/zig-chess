import logging
from contextlib import asynccontextmanager
from datetime import datetime

from mcp.server.fastmcp import FastMCP
import logging
import os
from logging import Handler
from logging.handlers import TimedRotatingFileHandler


os.chdir("../")

class Logger:
    def __init__(self, debug: bool = False) -> None:
        LOG_FORMAT = "%(asctime)s %(levelname)-8s %(module)-18s %(funcName)-18s %(message)s"
        DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

        self.formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
        self.loglevel = logging.DEBUG if debug else logging.INFO
        self.handlers: list[Handler] = []

    def load(self) -> None:
        self._add_console_handler()
        logging.basicConfig(level=self.loglevel, handlers=self.handlers)

    def _add_console_handler(self) -> None:
        handler = logging.StreamHandler()
        handler.setLevel(self.loglevel)
        handler.setFormatter(self.formatter)

        self.handlers.append(handler)

    def add_rotating_file_handler(
        self,
        log_path: str,
        rotate_when: str = "midnight",
        max_backup_files: int = 30,
    ) -> None:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)

        handler = TimedRotatingFileHandler(filename=log_path, when=rotate_when, backupCount=max_backup_files)
        handler.setLevel(self.loglevel)
        handler.setFormatter(self.formatter)

        self.handlers.append(handler)


# Logging setup
logger = Logger(debug=True)
script_dir = os.path.dirname(os.path.abspath(__file__))
log_filename = os.path.join(script_dir, "logs", f"mcp-server-{datetime.now().strftime('%Y%m%d%H%M%S')}.log")
logger.add_rotating_file_handler(log_path=log_filename)
logger.load()
LOGGER = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(server: FastMCP):
    LOGGER.info("MCP Ready")

    yield

    # TODO disconnect from database


mcp = FastMCP(name="Rapid MCP", lifespan=lifespan, host="0.0.0.0", port=8000)


@mcp.tool()
async def run_all_zig_tests():
    """
    Run Zig tests.
    """
    import subprocess
    LOGGER.info("Running Zig tests...")

    # Get the project root directory (parent of the mcp directory)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    try:
        result = subprocess.run(["zig", "build", "test"], check=True, capture_output=True, text=True, cwd=project_root)
        LOGGER.info("Zig tests passed:\n%s", result.stdout)        
        return "All tests passed! " + result.stdout
    except subprocess.CalledProcessError as e:
        LOGGER.error("Zig tests failed:\n%s", e.stderr)
        return e.stderr



if __name__ == "__main__":
    mcp.run()
