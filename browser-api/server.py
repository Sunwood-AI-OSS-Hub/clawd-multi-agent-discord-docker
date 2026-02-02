#!/usr/bin/env python3
"""
Browser API - FastAPI server for Playwright browser control
"""

import logging
import os
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from browser_manager import browser

# ロギング設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Request models
class BrowserOpenRequest(BaseModel):
    url: str = Field(..., description="開くURL")
    wait_until: str = Field("domcontentloaded", description="待機条件")


class BrowserClickRequest(BaseModel):
    selector: str = Field(..., description="クリックする要素のセレクタ")


class BrowserFillRequest(BaseModel):
    selector: str = Field(..., description="入力する要素のセレクタ")
    value: str = Field(..., description="入力する値")


class BrowserScreenshotRequest(BaseModel):
    path: str = Field("/app/screenshots/screenshot.png", description="スクリーンショットの保存先")


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup: start browser
    try:
        await browser.start()
        logger.info("Browser started successfully")
    except Exception as e:
        logger.warning(f"Failed to start browser on startup: {e}")
    yield
    # Shutdown: stop browser
    try:
        await browser.stop()
        logger.info("Browser stopped successfully")
    except Exception as e:
        logger.warning(f"Failed to stop browser on shutdown: {e}")


# CORS設定（デフォルトでは空リストで明示的な指定を要求）
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "").split(",")
if not ALLOWED_ORIGINS or ALLOWED_ORIGINS == [""]:
    ALLOWED_ORIGINS = []  # デフォルトでは許可しない

app = FastAPI(
    title="Cinderella Browser API",
    description="Playwright browser control API",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check
@app.get("/")
async def root():
    """ルートエンドポイント"""
    return {
        "service": "Cinderella Browser API",
        "version": "1.0.0",
        "browser_running": browser.is_running()
    }


@app.get("/health")
async def health():
    """ヘルスチェック"""
    return {"running": browser.is_running()}


# Open URL
@app.post("/open")
async def open_url(req: BrowserOpenRequest):
    """URLを開く"""
    try:
        page = browser.get_page()
        if not page:
            page = await browser.start()

        await page.goto(req.url, wait_until=req.wait_until)

        return {
            "success": True,
            "url": req.url,
            "title": await page.title()
        }
    except Exception as e:
        logger.error(f"Failed to open URL: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Snapshot - get page content with element refs
@app.get("/snapshot")
async def snapshot():
    """ページのスナップショットを取得（インタラクティブ要素の一覧）"""
    try:
        page = browser.get_page()
        if not page:
            raise HTTPException(status_code=400, detail="Browser not started")

        # Get all interactive elements
        elements = []

        selectors = [
            "button",
            "a[href]",
            "input[type='text']",
            "input[type='email']",
            "input[type='password']",
            "textarea",
            "select"
        ]

        ref_id = 1
        for selector in selectors:
            try:
                elems = await page.locator(selector).all()
                for elem in elems:
                    try:
                        role = await elem.evaluate("el => el.getAttribute('role')") or "generic"
                        tag = await elem.evaluate("el => el.tagName.toLowerCase()")

                        # Get accessible name
                        name = ""
                        if tag == "button":
                            name_text = await elem.inner_text()
                            name_label = await elem.evaluate("el => el.getAttribute('aria-label')")
                            name_name = await elem.evaluate("el => el.getAttribute('name')")
                            name = name_text or name_label or name_name or ""
                        elif tag == "a":
                            name_text = await elem.inner_text()
                            name_label = await elem.evaluate("el => el.getAttribute('aria-label')")
                            name = name_text or name_label or ""
                        elif tag in ["input", "textarea"]:
                            name_placeholder = await elem.evaluate("el => el.getAttribute('placeholder')")
                            name_name = await elem.evaluate("el => el.getAttribute('name')")
                            name_label = await elem.evaluate("el => el.getAttribute('aria-label')")
                            name = name_placeholder or name_name or name_label or ""
                        elif tag == "select":
                            name_name = await elem.evaluate("el => el.getAttribute('name')")
                            name_label = await elem.evaluate("el => el.getAttribute('aria-label')")
                            name = name_name or name_label or ""

                        # Generate selector for this element
                        try:
                            elem_selector = await elem.evaluate("""
                                el => {
                                    if (el.id) return '#' + el.id;
                                    if (el.className) return '.' + el.className.split(' ')[0];
                                    return el.tagName.toLowerCase();
                                }
                            """)
                        except:
                            elem_selector = tag

                        elements.append({
                            "ref": f"@e{ref_id}",
                            "selector": elem_selector,
                            "role": role,
                            "tag": tag,
                            "name": name[:100] if name else ""
                        })
                        ref_id += 1
                    except Exception as e:
                        logger.debug(f"Failed to process element: {e}")
                        continue
            except Exception as e:
                logger.debug(f"Failed to process selector {selector}: {e}")
                continue

        return {
            "success": True,
            "url": page.url,
            "title": await page.title(),
            "elements": elements
        }
    except Exception as e:
        logger.error(f"Failed to get snapshot: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Click element
@app.post("/click")
async def click(req: BrowserClickRequest):
    """要素をクリック"""
    try:
        page = browser.get_page()
        if not page:
            raise HTTPException(status_code=400, detail="Browser not started")

        await page.click(req.selector)

        return {
            "success": True,
            "action": "click",
            "selector": req.selector
        }
    except Exception as e:
        logger.error(f"Failed to click element: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Fill input
@app.post("/fill")
async def fill(req: BrowserFillRequest):
    """入力フィールドに入力"""
    try:
        page = browser.get_page()
        if not page:
            raise HTTPException(status_code=400, detail="Browser not started")

        await page.fill(req.selector, req.value)

        return {
            "success": True,
            "action": "fill",
            "selector": req.selector,
            "value": req.value
        }
    except Exception as e:
        logger.error(f"Failed to fill element: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Get text from element
@app.get("/text")
async def get_text(selector: str):
    """要素のテキストを取得"""
    try:
        page = browser.get_page()
        if not page:
            raise HTTPException(status_code=400, detail="Browser not started")

        text = await page.inner_text(selector)

        return {
            "success": True,
            "selector": selector,
            "text": text
        }
    except Exception as e:
        logger.error(f"Failed to get text: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Take screenshot
@app.post("/screenshot")
async def screenshot(req: BrowserScreenshotRequest):
    """スクリーンショットを撮る"""
    try:
        page = browser.get_page()
        if not page:
            raise HTTPException(status_code=400, detail="Browser not started")

        # Ensure directory exists
        screenshot_dir = os.path.dirname(req.path)
        if screenshot_dir:
            os.makedirs(screenshot_dir, exist_ok=True)

        await page.screenshot(path=req.path)

        return {
            "success": True,
            "path": req.path
        }
    except Exception as e:
        logger.error(f"Failed to take screenshot: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Close browser
@app.post("/close")
async def close():
    """ブラウザを閉じる"""
    try:
        await browser.stop()
        return {"success": True, "message": "Browser closed"}
    except Exception as e:
        logger.error(f"Failed to close browser: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
