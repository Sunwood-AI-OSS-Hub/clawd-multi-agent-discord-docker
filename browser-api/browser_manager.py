#!/usr/bin/env python3
"""
Browser Manager - Singleton Playwright browser session management (Async)
"""

from playwright.async_api import async_playwright, BrowserContext, Page, Playwright
from pathlib import Path
from typing import Optional
import asyncio

USER_DATA_DIR = Path("/app/chrome-profile")


class BrowserManager:
    """Singleton browser manager for persistent Chrome session"""

    _instance: Optional["BrowserManager"] = None
    _lock = asyncio.Lock()

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        self._playwright: Optional[Playwright] = None
        self._context: Optional[BrowserContext] = None
        self._page: Optional[Page] = None
        self._initialized = True

    async def start(self) -> Page:
        """Start browser and return page"""
        if self._page is not None:
            return self._page

        self._playwright = await async_playwright().start()

        # Launch real Chrome with persistent profile
        self._context = await self._playwright.chromium.launch_persistent_context(
            user_data_dir=str(USER_DATA_DIR),
            channel="chrome",  # Real Google Chrome
            headless=False,    # Display on Xvfb
            viewport={"width": 1920, "height": 1080},
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-dev-shm-usage",
            ],
        )

        # Get or create page
        if len(self._context.pages) > 0:
            self._page = self._context.pages[0]
        else:
            self._page = await self._context.new_page()

        return self._page

    def get_page(self) -> Optional[Page]:
        """Get current page without starting browser"""
        return self._page

    async def stop(self):
        """Stop browser"""
        if self._context:
            await self._context.close()
            self._context = None
        if self._playwright:
            await self._playwright.stop()
            self._playwright = None
        self._page = None

    def is_running(self) -> bool:
        """Check if browser is running"""
        return self._page is not None


# Global singleton
browser = BrowserManager()
