"""Written before any test existed - the eval fixture for the Iron Law case."""

import time

import httpx


class TrinoClient:
    def __init__(self, base_url: str, timeout: float = 5.0) -> None:
        self._base_url = base_url
        self._timeout = timeout
        self._client = httpx.Client(base_url=base_url, timeout=timeout)

    def run_query(self, sql: str) -> list[dict[str, object]]:
        delay = 0.5

        for attempt in range(3):
            try:
                response = self._client.post("/v1/statement", content=sql)
                response.raise_for_status()
                return response.json()["data"]
            except (httpx.TimeoutException, httpx.HTTPStatusError):
                if attempt == 2:
                    raise
                time.sleep(delay)
                delay *= 2

        raise RuntimeError("unreachable")
