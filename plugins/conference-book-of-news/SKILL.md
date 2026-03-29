---
name: conference-book-of-news
description: Automatically create a comprehensive "Book of News" PDF from any conference — scrapes sessions, captures video screenshots, extracts slide content via OCR, generates AI summaries, and produces an Ignite-style publication with images, announcements, code samples, and indexes.
confidence: high
---

# Conference Book of News

## Overview

This skill enables AI agents (or Squad teams) to automatically generate a comprehensive "Book of News" PDF from any conference with recorded sessions. The agent navigates the conference website, discovers all sessions with video recordings, captures screenshots at key moments during each video, extracts slide content via OCR, generates AI summaries, and assembles everything into a publication-grade PDF document.

The output is a professional, Ignite-style publication featuring: a cover page, executive summary, table of contents organized by category, detailed per-session pages (with hero images, screenshot grids, OCR-extracted topics, AI-generated summaries, product announcements, code/demo galleries, and key takeaways), and comprehensive appendices (Top 10 Highlights, Technology Index, Speaker Directory). The entire document is self-contained with embedded images, making it easy to distribute and archive.

**Example use cases:**
- Microsoft Ignite, Build, MVP Summit
- Google I/O, Cloud Next
- AWS re:Invent, re:Mars
- KubeCon, DockerCon, PyCon
- Company internal conferences, quarterly all-hands, training events

---

## Prerequisites

### Tools & Dependencies

1. **`playwright-cli` skill** (browser automation)
   - For navigating conference websites
   - Capturing video screenshots
   - Converting HTML → PDF

2. **Python 3.10+** with packages:
   ```bash
   pip install Pillow rapidocr-onnxruntime
   ```
   - `Pillow`: Image processing (JPEG conversion, resizing)
   - `rapidocr-onnxruntime`: OCR extraction from screenshots

3. **Persistent browser session** with auth cookies
   - Many conference sites require authentication (SSO, registration)
   - Use `playwright-cli` to log in once, save cookies
   - Reuse session for all subsequent requests

4. **Disk space**: ~2-5GB for screenshots
   - 7 screenshots per session × number of sessions
   - Example: 200 sessions = ~1,400 images = ~3GB

5. **Local HTTP server** (for PDF conversion)
   - `python -m http.server` (built-in, no install)
   - Serves HTML to Playwright for rendering

---

## Pipeline Steps

### Step 1: Session Discovery

**Goal:** Extract all sessions from the conference catalog, focusing on those with video recordings.

**Process:**
1. Navigate to the conference schedule/catalog page
2. Extract session metadata:
   - Session title
   - Speakers (name, title, company)
   - Description/abstract
   - Video URL (recording link)
   - Session page URL (for "Watch Session" links)
   - Category/track
3. Filter to sessions WITH video recordings (skip sessions without video)
4. Save to `sessions.json`:
   ```json
   [
     {
       "title": "Keynote: The Future of AI",
       "speakers": ["Satya Nadella"],
       "description": "Opening keynote exploring...",
       "video_url": "https://medius.studios.ms/video/...",
       "session_url": "https://ignite.microsoft.com/sessions/...",
       "category": "Keynotes"
     }
   ]
   ```

**Playwright techniques:**
- Use `playwright-cli navigate`, `find`, `get-attribute` to scrape catalog
- For paginated catalogs: loop through pages or use infinite scroll
- For authenticated sites: ensure cookies are loaded before navigating

---

### Step 2: Video Screenshot Capture

**Goal:** For each session video, capture 7 evenly-spaced screenshots showing key slides/moments.

**Process:**
1. **Navigate to video URL**
   - Load the video embed/player page
   - Wait for player to initialize

2. **Click Play button**
   - **CRITICAL:** Use `playwright-cli click` with the play button reference/selector
   - Example: `playwright-cli click e5` (for Medius player ref attribute)
   - Why not `run-code`? Button labels often include full session titles, making text-based locators fragile

3. **Get video duration**
   - Inject JavaScript: `document.querySelector('video').duration`
   - **IMPORTANT:** Duration returns `NaN` or `Infinity` until video buffers
   - Poll with 1-second retry until duration is valid (usually 5-10s)

4. **Calculate 7 timestamps**
   - Divide duration by 8 to get interval
   - Timestamps: `interval * 1`, `interval * 2`, ..., `interval * 7`
   - Example (3600s video): 450s, 900s, 1350s, 1800s, 2250s, 2700s, 3150s

5. **Seek and capture**
   - For each timestamp:
     - Seek: `document.querySelector('video').currentTime = seconds`
     - Wait 2-2.5 seconds for frame to render (critical for sharp images)
     - Screenshot: `playwright-cli screenshot --filename={index}-{title-slug}-{MMmSSs}.png`

**Filename format:**
```
000-keynote-future-of-ai-07m30s.png
000-keynote-future-of-ai-15m00s.png
001-azure-ai-studio-12m45s.png
```

**Key timing parameters:**
- Buffer wait: 5-10 seconds (until `duration` is valid)
- Seek wait: 2-2.5 seconds (for frame render)
- Total per screenshot: ~4-5 seconds
- Total per session (7 screenshots): ~30-40 seconds

---

### Step 3: OCR Extraction

**Goal:** Extract all text from screenshots using OCR, filtering out UI noise.

**Process:**
1. **Run RapidOCR** on every screenshot:
   ```python
   from rapidocr_onnxruntime import RapidOCR
   ocr = RapidOCR()
   
   for screenshot in screenshots:
       result, elapse = ocr(screenshot)
       texts = [line[1] for line in result] if result else []
   ```

2. **Filter Teams/Zoom/WebEx UI noise** (see section 6 for full list)
   - Meeting controls: "Take control", "People", "Raise", "React", etc.
   - Browser chrome: "localhost", "http://", "favicon"
   - Timestamps, lone numbers, single characters
   - 5+ consecutive consonants (OCR garbage)

3. **Save to `ocr-extracts.json`**:
   ```json
   {
     "0": [
       "The Future of AI",
       "Satya Nadella",
       "Microsoft CEO",
       "AI will transform every industry",
       ...
     ],
     "1": [
       "Azure AI Studio",
       "Build and deploy AI models",
       ...
     ]
   }
   ```
   - Key by session index (as string) for easy lookup
   - Store as array of cleaned text lines per session

---

### Step 4: AI Summary Generation

**Goal:** Generate comprehensive summaries and key takeaways for every session.

**Process:**
1. **Prepare context** for each session:
   - Session title, speakers, description
   - OCR text from all 7 screenshots
   - Video URL (for reference)

2. **Generate via background agent or LLM API:**
   ```python
   # Example prompt:
   """
   Generate a summary for this conference session:
   
   Title: {title}
   Speakers: {speakers}
   Description: {description}
   
   Slide content (OCR):
   {ocr_text}
   
   Provide:
   1. Multi-paragraph detailed summary (3-5 paragraphs)
   2. List of 5-8 key takeaways (bullet points)
   
   Focus on: technical details, product announcements, demos, new features.
   """
   ```

3. **Save as importable Python module** (`summaries.py`):
   ```python
   ALL_SUMMARIES = {
       0: {
           "summary": "In this keynote, Satya Nadella...",
           "takeaways": [
               "AI will be integrated into every Microsoft product",
               "New Copilot features announced...",
               ...
           ]
       },
       1: { ... }
   }
   
   CATEGORIES = {
       "Keynotes": [0],
       "AI & ML": [1, 5, 12],
       "Developer Tools": [2, 3, 8],
       ...
   }
   ```

4. **Batch processing:**
   - Use background agent with Python REPL to generate all summaries
   - Write results incrementally (session-by-session) to avoid loss
   - Typical time: 30-60 seconds per session (depending on LLM)

---

### Step 5: HTML Generation

**Goal:** Build a rich, self-contained HTML document with all content and embedded images.

**Key Components:**

#### **1. Cover Page**
- Conference name, dates, logo
- Background image (hero from keynote or custom graphic)
- Title: "Book of News"

#### **2. Executive Summary**
- Conference overview (2-3 paragraphs)
- High-level themes and trends
- Top announcements (from Top 10 appendix)

#### **3. Table of Contents**
- Organized by category
- Session title, speakers, page number reference

#### **4. Per-Session Pages**
Each session gets a detailed page with:

**Header:**
- Session title (h1)
- Speakers (name, title, company)
- "Watch Session" link (clickable, opens video)

**Original Description:**
- Session abstract from catalog (italic, gray text)

**Hero Image:**
- First screenshot, full-width (1400px max)
- Smart-cropped to remove meeting platform UI (see Lesson #7)
- JPEG quality 96 with 4:4:4 chroma (`subsampling=0`) for sharp text
- Embedded as base64 data URI

**Screenshot Grid:**
- Remaining 6 screenshots in 3-column layout
- Each image: 1000px wide (not 700px — smaller is unreadable)
- Smart-cropped (same as hero)
- Caption below each: OCR-extracted slide heading + timestamp
  - Example: *"Azure AI Studio Overview — at 12:45"*

**Topics Covered:**
- Extracted from OCR slide headings (h2, h3 text)
- Bullet list of key topics discussed
- Example:
  - Azure AI Studio
  - Model deployment
  - Prompt engineering
  - Responsible AI

**Detailed Summary:**
- Multi-paragraph AI-generated summary (3-5 paragraphs)
- Technical details, context, significance

**Announcements & Products:**
- Product names + context sentences from summary
- Extracted using product dictionary (see Configuration section)
- Format: "**Azure AI Studio**: A new unified platform for..."

**Code & Demos Gallery:**
- Screenshots identified as containing code/IDE/terminal
- Detection: OCR text scored for code patterns: `{}`, `=>`, `function`, `class`, `import`, etc.
- Display full-width (1400px) for readability
- Caption: "Code sample from {timestamp}"

**Links Shared:**
- URLs extracted from OCR text AND AI summaries
- Regex: `https?://[^\s<>"')\]]+`
- Filter out noise URLs: localhost, 127.0.0.1, privacy/cookie links, the video player URL itself
- Displayed as clickable links in a green-bordered section
- Typically 10-20% of sessions have extractable links

**Key Takeaways:**
- Bullet list from AI summary
- 5-8 actionable insights

#### **5. Appendices**

**Top 10 Highlights:**
- Sessions ranked by announcement density
- Metric: count of unique product names mentioned
- Display: title, speakers, hero image, 2-sentence summary

**Technology Index:**
- Alphabetical list of every product/tool mentioned
- Cross-reference to sessions where discussed
- Example:
  - **Azure AI Studio**: Sessions 1, 5, 12, 18
  - **Copilot**: Sessions 1, 3, 7, 9, 14, 22

**Speaker Directory:**
- Alphabetical list of all presenters
- Name, title, company
- Links to their sessions

#### **Technical Implementation:**

**Smart Crop (critical for meeting recordings):**
```python
def smart_crop(img):
    """Remove meeting platform UI chrome from screenshots."""
    w, h = img.size
    
    # 1. Black bars: scan for first/last bright rows
    top = 0
    for y in range(0, h // 3, 3):
        bright = sum(1 for x in range(0, w, w//10) 
                     if sum(img.getpixel((x, y))[:3])/3 > 25)
        if bright >= 3:
            top = y; break
    
    bottom = h
    for y in range(h - 1, h * 2 // 3, -3):
        bright = sum(1 for x in range(0, w, w//10) 
                     if sum(img.getpixel((x, y))[:3])/3 > 25)
        if bright >= 3:
            bottom = y + 1; break
    
    # 2. Controls bar: bright row in top 80px of content
    controls_end = top
    for y in range(top, min(top + 80, h), 2):
        row_bright = sum(1 for x in range(0, w, w//20) 
                        if sum(img.getpixel((x, y))[:3])/3 > 100)
        if row_bright >= w // 20 // 2:
            controls_end = y + 2
    if controls_end > top:
        top = controls_end + 5
    
    # 3. Gallery border: thin bright strip with dark area to its left
    right = w
    sample_ys = list(range(top + 50, bottom - 50, 30))
    for x_check in range(int(w * 0.9), int(w * 0.6), -2):
        hits = 0
        for y_s in sample_ys:
            b = sum(img.getpixel((x_check, y_s))[:3]) / 3
            b_left = sum(img.getpixel((max(0, x_check - 30), y_s))[:3]) / 3
            if 40 < b < 120 and b_left < 40 and b > b_left + 15:
                hits += 1
        if hits >= len(sample_ys) * 0.6:
            right = x_check - 5; break
    
    # 4. Bottom nav: trim 25px
    bottom = max(top + 100, bottom - 25)
    
    # Safety: don't over-crop
    if (right < w * 0.5) or (bottom - top < h * 0.3):
        return (0, 0, w, h)
    return (0, top, right, bottom)
```

**Image embedding with HD quality:**
```python
from PIL import Image
import base64
from io import BytesIO

def encode_image(filepath, max_width=1400):
    img = Image.open(filepath)
    crop_box = smart_crop(img)
    if crop_box != (0, 0, img.width, img.height):
        img = img.crop(crop_box)
    if img.width > max_width:
        ratio = max_width / img.width
        img = img.resize((max_width, int(img.height * ratio)), Image.LANCZOS)
    buf = BytesIO()
    # quality=96 + subsampling=0 (4:4:4) = HD text readability
    img.convert('RGB').save(buf, format='JPEG', quality=96, 
                            subsampling=0, optimize=True)
    return base64.b64encode(buf.getvalue()).decode()
```

**Why base64?**
- Self-contained HTML (no external file dependencies)
- Required for PDF conversion (Playwright needs all resources inline)
- Downside: Large HTML file (100-160MB for HD), but acceptable for ephemeral build artifact

**Image quality tradeoffs:**
| Quality | Subsampling | Result | Use Case |
|---------|-------------|--------|----------|
| 62 | 4:2:0 (default) | Blurry text, small file | Never — too low |
| 85 | 4:2:0 (default) | OK text, moderate file | Quick drafts only |
| 96 | 4:4:4 (subsampling=0) | **Sharp text, HD quality** | **Publication output** |
| PNG | N/A | Lossless, 5x larger | Too large for 100+ sessions |

**Product name extraction:**
```python
# Use known product dictionary, not naive regex
PRODUCT_FAMILIES = [
    "Azure", "Copilot", "Visual Studio", "GitHub",
    "Windows", ".NET", "TypeScript", "VS Code",
    "Power Platform", "Dynamics", "Microsoft 365"
]

# Extract with context (qualifier + product name)
# Good: "new Azure AI Studio", "announcing Copilot Pro"
# Bad: "John Azure" (person name), "March 2024" (date)
```

---

### Step 6: PDF Conversion

**Goal:** Convert the HTML document to a high-quality PDF.

**Process:**

1. **Start local HTTP server:**
   ```bash
   cd output_directory
   python -m http.server 8000
   ```

2. **Load HTML in Playwright browser:**
   ```
   playwright-cli navigate http://localhost:8000/book-of-news.html
   ```

3. **Wait for images to load:**
   - Base64 images load instantly, but browser needs time to decode/render
   - Wait 5-10 seconds or use `playwright-cli wait` for specific element

4. **Generate PDF:**
   ```
   playwright-cli pdf --filename=book-of-news.pdf
   ```
   - Default: Letter size, portrait orientation
   - For better layout: Consider landscape for image grids
   - Print backgrounds: Enabled by default (needed for styled sections)

5. **Verify output:**
   - Open PDF in viewer
   - Zoom to 200% and check image sharpness
   - Verify all links are clickable
   - Check TOC page numbers (if using CSS page breaks)

**PDF optimization:**
- File size: 50-200MB typical (for 100-200 sessions)
- Alternative: Use external image files instead of base64, but requires bundling
- Alternative: Compress images more aggressively (quality 70), trade-off with readability

---

## Configuration

Adapt the skill to any conference by configuring these parameters:

| Parameter | Example | Description |
|-----------|---------|-------------|
| **Conference name** | "Microsoft Ignite 2026" | Used in cover page, headers, footer |
| **Conference dates** | "March 17-21, 2026" | Displayed on cover |
| **Schedule URL** | `https://ignite.microsoft.com/sessions` | Starting point for session discovery |
| **Auth required** | `true`/`false` | Whether the site needs authentication |
| **Video player type** | `"medius"` / `"youtube"` / `"vimeo"` / `"custom"` | How to interact with the video player |
| **Play button selector** | `"ref=e5"` or `"button[aria-label*='Play']"` | How to click play |
| **Video element selector** | `"video"` or `"#player video"` | For duration/seek operations |
| **Screenshots per session** | `7` (default) | Number of timestamps to capture |
| **Screenshot wait time** | `2.5` seconds | Wait after seek for frame render |
| **Image quality** | `85` (JPEG quality 0-100) | Higher = sharper but larger PDF |
| **Image width (hero)** | `1400` px | Full-width images |
| **Image width (grid)** | `700` px | Grid thumbnail images |
| **Product families** | `["Azure", "AWS", "GCP", ...]` | For announcement extraction |
| **Categories** | User-defined or auto-detected | How to group sessions in TOC |
| **OCR language** | `"en"` (default) | For non-English conferences |

**Configuration file example** (`config.json`):
```json
{
  "conference": {
    "name": "Microsoft Ignite 2026",
    "dates": "March 17-21, 2026",
    "logo_url": "https://ignite.microsoft.com/logo.png"
  },
  "scraping": {
    "schedule_url": "https://ignite.microsoft.com/sessions",
    "auth_required": true,
    "video_player": "medius"
  },
  "capture": {
    "screenshots_per_session": 7,
    "seek_wait_seconds": 2.5,
    "jpeg_quality": 85
  },
  "products": {
    "families": ["Azure", "Copilot", "Visual Studio", "GitHub", "Windows", ".NET"]
  }
}
```

---

## Adapting to Different Video Players

Each conference uses different video hosting platforms. Here's how to adapt:

| Platform | Play Method | Seek Method | Get Duration | Notes |
|----------|-------------|-------------|--------------|-------|
| **Medius** (Microsoft) | `playwright-cli click e5` | `el.currentTime = seconds` | `el.duration` (poll until not NaN) | Play button has `ref="e5"` attribute |
| **YouTube embed** | Click play overlay | `player.seekTo(seconds)` | `player.getDuration()` | Use YouTube IFrame API |
| **Vimeo embed** | Click play button | `player.setCurrentTime(seconds)` | Vimeo Player API | Need Vimeo SDK loaded |
| **Generic HTML5 video** | `video.play()` | `video.currentTime = seconds` | `video.duration` | Standard video element |
| **Custom players** | Inspect DOM for play button | Check player API docs | Check player API docs | May need to inject player scripts |

**Example: YouTube**
```javascript
// In Playwright run-code:
const player = new YT.Player('player', {
  events: {
    'onReady': () => {
      const duration = player.getDuration();
      player.seekTo(seconds, true);
    }
  }
});
```

**Example: Medius (Microsoft Studios)**
```javascript
// Click play via ref attribute
// (playwright-cli click e5)

// Then seek via video element
const video = document.querySelector('video');
video.currentTime = seconds;

// Get duration (with polling)
let duration = video.duration;
while (isNaN(duration) || duration === Infinity) {
  await new Promise(r => setTimeout(r, 1000));
  duration = video.duration;
}
```

**Debugging tips:**
- Inspect video player DOM: Use browser DevTools to find play button, video element
- Check for player libraries: Look for `YT`, `Vimeo`, `jwplayer` in page scripts
- Test seek behavior: Some players need `play()` before seeking works
- Handle ads: Some platforms show pre-roll ads; wait for content to start

---

## OCR Noise Filtering

OCR from video screenshots captures 30-50% noise (UI controls, browser chrome, garbage text). **Aggressive filtering is essential.**

**Full filter list** (remove any line containing these patterns):

### **Meeting Platform UI:**
```
Take control, Pop out, People, Raise, React, Leave, More actions,
Microphone, Camera, Share screen, Record, Chat, Participants,
Show conversation, You're presenting, Stop presenting,
Mute all, Unmute all, Spotlight, Pin, Grid view, Large gallery,
Together mode, Breakout rooms, Live captions, Blur background,
Virtual background, Settings, Devices, Call quality,
Screen sharing paused, Reconnecting, Connection lost,
Teams, Zoom, WebEx, Join audio, Computer audio, Phone audio
```

### **Browser Chrome:**
```
localhost, http://, https://, favicon, address bar, bookmarks,
extensions, new tab, close tab, reload, back, forward,
history, downloads, settings, help, about, dev tools,
inspect element, console, network, sources
```

### **Office Ribbon (from shared screens):**
```
File, Home, Insert, Draw, Design, Layout, References, Mailings,
Review, View, Help, Tell me what you want to do, Share, Comments,
Undo, Redo, Cut, Copy, Paste, Format Painter, Font, Paragraph,
Styles, Editing, Clipboard, Slide, New Slide, Section, Transitions
```

### **Generic Noise:**
```
undefined, NaN, null, scrollbar, tooltip, overlay, popup,
modal, dialog, button, checkbox, radio, dropdown, menu,
Loading..., Please wait, Buffering, Error, Retry,
OK, Cancel, Submit, Close, X, ✓, ✗
```

### **Patterns (Regex):**
```python
import re

def is_noise(text):
    # Timestamps: MM:SS, HH:MM:SS
    if re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', text):
        return True
    
    # Single characters or numbers
    if len(text) <= 2:
        return True
    
    # 5+ consecutive consonants (OCR garbage)
    if re.search(r'[bcdfghjklmnpqrstvwxyz]{5,}', text.lower()):
        return True
    
    # All caps with no vowels (likely OCR error)
    if text.isupper() and not re.search(r'[aeiou]', text.lower()):
        return True
    
    # URL fragments without protocol
    if re.match(r'^www\.|\.com$|\.org$|\.net$', text):
        return True
    
    return False
```

### **Contextual Filtering:**
- Remove lines that appear in >80% of screenshots (likely persistent UI)
- Remove lines that match known noise patterns from previous conferences
- Keep lines with title case (likely slide headings)
- Keep lines with product names (even if short)

---

## What Went Wrong — Lessons Learned

Real lessons from the MVP Summit 2026 implementation:

### **1. OCR noise is 30-50% of extracted text**
- **Problem:** Raw OCR includes Teams UI, timestamps, lone letters, garbage text
- **Solution:** Aggressive filtering (see section 6) + contextual deduplication
- **Result:** Clean slide headings and topics for each session

### **2. `playwright-cli click` works where `run-code` button locators fail**
- **Problem:** Play button labels include full session titles (100+ chars), making text-based locators fragile
- **Solution:** Use `ref` or `aria-label` attributes with `playwright-cli click`
- **Example:** `playwright-cli click e5` (Medius player ref attribute)
- **Avoid:** `click button:has-text("Play Session: The Future of AI and Machine Learning in Azure Cloud Services with Copilot Integration")`

### **3. Video duration returns NaN/Infinity until buffered**
- **Problem:** `video.duration` is unreliable immediately after page load
- **Solution:** Poll with 1-second retry, timeout after 20 seconds
- **Code:**
  ```javascript
  let duration = video.duration;
  let attempts = 0;
  while ((isNaN(duration) || duration === Infinity) && attempts < 20) {
    await new Promise(r => setTimeout(r, 1000));
    duration = video.duration;
    attempts++;
  }
  ```

### **4. 2-2.5 second wait after seeking needed for frame to render**
- **Problem:** Screenshots immediately after `currentTime` assignment show black frames or previous content
- **Solution:** Wait 2-2.5 seconds after seek before screenshot
- **Why:** Browser needs time to decode and render the new frame
- **Tested values:** 1s (too fast), 2s (mostly works), 2.5s (reliable)

### **5. Product name extraction via regex pulls person names and dates**
- **Problem:** Naive regex `\b[A-Z][a-z]+ [A-Z][a-z]+\b` matches "John Smith", "March 2024"
- **Solution:** Use known-product dictionary (Azure, Copilot, etc.) + qualifier matching
- **Example:** "new Azure AI Studio" (good), "John Azure" (filtered as likely person name)

### **6. JPEG quality AND chroma subsampling are critical for text readability**
- **Problem:** Default PIL JPEG quality (75) and chroma subsampling (4:2:0) make slide text blurry when zoomed
- **Solution:** Use `quality=96, subsampling=0` (4:4:4 chroma — no color channel downsampling)
- **Why subsampling=0 matters:** Default JPEG uses 4:2:0 which halves color resolution. Text edges use color contrast, so 4:2:0 blurs text. `subsampling=0` (4:4:4) preserves full color resolution — critical for reading slide text
- **File size impact:** Quality 85 + 4:2:0 = ~400KB/image; Quality 96 + 4:4:4 = ~1.2MB/image (3x larger but readable)
- **Grid images:** Use max_width=1000px (not 700px) for the 3-column grid
- **Hero images:** max_width=1400px (full width, no downscale if source is smaller)
- **Code gallery:** max_width=1400px (users need to read code in screenshots)
- **PIL code:** `img.save(buf, format='JPEG', quality=96, subsampling=0, optimize=True)`

### **7. Smart Crop — removing meeting platform UI chrome is essential**
- **Problem:** Video screenshots of recorded sessions include the meeting platform UI: controls bar, participant gallery sidebar, black letterbox bars, slide navigation bar. These waste 40-50% of the image and obscure the actual slide content.
- **Solution:** Implement a `smart_crop()` function that detects and removes each UI element:
  1. **Black bars (top/bottom):** Scan rows for brightness — first/last rows with ≥3 bright sample points mark content boundaries
  2. **Controls bar:** Scan first 80px of content for a fully bright row (meeting controls). Trim past it (+5px).
  3. **Participant gallery border:** Scan x from 90%→60% of width. At each x, sample y positions across the content area. Gallery border has brightness 40-120 while 30px to its left is <40 with >15 brightness difference. If 60%+ of y-samples match, crop at that x.
  4. **Bottom nav bar:** Trim 25px from bottom (slide navigation controls)
- **Safety:** If crop would remove >50% of width or >70% of height, bail out (return original dimensions)
- **Results:** Teams meetings: 1241×1280 → 1079×673 (with gallery) or 1241×673 (without). ~47% of pixels removed.
- **Impact:** Images become dramatically more readable because the actual slide fills the frame
- **Platform-specific:** The exact pixel patterns vary by platform (Teams, Zoom, WebEx). Test calibration screenshots first.

### **8. base64 images make HTML huge (100+MB) but needed for self-contained PDF**
- **Problem:** HTML file size becomes 100-160MB with HD embedded images
- **Solution:** Acceptable for ephemeral build artifact; clean up after PDF generation
- **Alternative:** Use external image files, but requires bundling for distribution
- **Why base64:** Playwright PDF conversion needs all resources inline (no external URLs)
- **Load timeout:** For large HTML (100+ MB), increase Playwright goto timeout to 300s: `page.goto(url, { timeout: 300000 })`

### **9. "Code samples" from OCR are mostly garbage**
- **Problem:** OCR on code screenshots produces mangled syntax, wrong indentation
- **Solution:** Show actual screenshots of code slides instead of OCR text
- **Detection:** Score OCR for code patterns (`{}`, `=>`, `function`, `import`) → if high score, show image
- **Result:** Users can zoom into image to read actual code, not OCR approximation

### **10. Session discovery pagination is fragile**
- **Problem:** Conference sites use infinite scroll, virtual scrolling, or complex pagination
- **Solution:** Use `playwright-cli scroll` to trigger lazy loading, or find "Load More" button
- **Alternative:** If site has API, scrape JSON directly (check Network tab)

### **11. Authentication state expires during long scraping sessions**
- **Problem:** After 1-2 hours of scraping, auth cookies expire and video pages return 401
- **Solution:** Refresh auth token periodically (every 30 mins), or re-login
- **Best practice:** Use dedicated service account with long-lived tokens for automation

---

## Output Quality Checklist

Use this checklist to verify the generated Book of News meets quality standards:

### **Session Pages:**
- [ ] All sessions have 7 screenshots (1 hero + 6 grid)
- [ ] Hero image is full-width (1400px) and sharp when zoomed
- [ ] Grid images are 3-column layout (700px each)
- [ ] Image captions show OCR-extracted slide heading + timestamp
  - Example: *"Azure AI Studio Architecture (15m30s)"*
- [ ] Topics Covered section lists actual slide headings (not noise)
- [ ] Detailed Summary is 3-5 paragraphs, technically accurate
- [ ] Announcements show product name + context sentence
  - Example: **Azure AI Studio**: A new unified platform for building and deploying AI models
- [ ] Code gallery shows actual IDE/terminal screenshots (not OCR text)
- [ ] No code gallery for sessions without code content
- [ ] Links Shared lists actual URLs mentioned in slides
- [ ] Key Takeaways are actionable bullet points (5-8 items)

### **Images:**
- [ ] Smart-cropped: no meeting UI chrome (controls bar, participant gallery, black bars)
- [ ] JPEG quality 96 with `subsampling=0` (4:4:4 chroma for sharp text)
- [ ] Hero images at 1400px max width
- [ ] Grid images at 1000px max width
- [ ] Code gallery images at 1400px max width
- [ ] No black frames or loading spinners
- [ ] No duplicates (same timestamp captured twice)
- [ ] Filenames follow convention: `{index}-{title-slug}-{MMmSSs}.png`

### **OCR Quality:**
- [ ] No Teams/Zoom UI text in Topics or Announcements
- [ ] No timestamps (MM:SS) in extracted topics
- [ ] No single letters or lone numbers
- [ ] No "undefined", "NaN", "scrollbar" garbage
- [ ] Slide headings are title-cased and coherent

### **Metadata & Links:**
- [ ] Session URLs are clickable and open correct video
- [ ] Speaker names are spelled correctly (verify against catalog)
- [ ] Categories match conference tracks
- [ ] All sessions assigned to a category

### **Appendices:**
- [ ] **Top 10 Highlights** ranked by announcement density
- [ ] Top 10 includes hero images
- [ ] **Technology Index** lists all products alphabetically
- [ ] Tech Index cross-references to session numbers
- [ ] **Speaker Directory** is alphabetical
- [ ] Speaker Directory links to their sessions

### **PDF Output:**
- [ ] File size is reasonable (80-200MB for 100-200 sessions with HD images)
- [ ] All images render correctly (no broken images)
- [ ] Large HTML (100+ MB) loaded with extended timeout (300s)
- [ ] Links are clickable in PDF viewer
- [ ] Text is selectable (not rasterized)
- [ ] Page breaks are clean (no orphaned headings)
- [ ] TOC page numbers are accurate (if using CSS page numbers)

### **Final Validation:**
- [ ] Spot-check 10 random sessions for accuracy
- [ ] Verify Top 10 sessions actually have high announcement density
- [ ] Cross-check Tech Index against actual session content
- [ ] Test PDF on multiple viewers (Acrobat, Chrome, macOS Preview)
- [ ] Share with a colleague for readability feedback

---

## Example Workflow

**Step-by-step for Microsoft Ignite 2026:**

```bash
# 1. Authenticate and save session
playwright-cli navigate https://ignite.microsoft.com
# (log in via SSO)
playwright-cli save-cookies ignite-cookies.json

# 2. Scrape session catalog
playwright-cli load-cookies ignite-cookies.json
playwright-cli navigate https://ignite.microsoft.com/sessions
# ... extract session metadata to sessions.json

# 3. Capture screenshots for all sessions
for session in sessions.json:
    playwright-cli navigate {video_url}
    playwright-cli click e5  # play button
    # ... seek to 7 timestamps, screenshot each

# 4. Run OCR on all screenshots
python ocr_extract.py --input screenshots/ --output ocr-extracts.json

# 5. Generate AI summaries
# (use background agent with Python REPL)
# ... write to summaries.py

# 6. Build HTML document
python build_book.py --sessions sessions.json --ocr ocr-extracts.json --summaries summaries.py --output book-of-news.html

# 7. Convert to PDF
python -m http.server 8000 &
playwright-cli navigate http://localhost:8000/book-of-news.html
playwright-cli pdf --filename ignite-2026-book-of-news.pdf

# 8. Verify output
open ignite-2026-book-of-news.pdf
# (check quality with checklist above)
```

---

## Troubleshooting

### **Problem: Video duration is always NaN**
- **Cause:** Video not buffered, or wrong selector
- **Solution:** Wait longer (up to 30s), verify `video` element exists
- **Check:** Open DevTools, run `document.querySelector('video').duration` manually

### **Problem: Screenshots are black frames**
- **Cause:** Not waiting long enough after seek
- **Solution:** Increase wait time to 3-4 seconds
- **Check:** Manually seek in browser, observe how long until frame appears

### **Problem: Play button click does nothing**
- **Cause:** Wrong selector, or button requires hover first
- **Solution:** Use `playwright-cli hover` before click, or try clicking on video element directly
- **Check:** Inspect play button in DevTools, verify ref/aria-label attributes

### **Problem: OCR extraction is all garbage**
- **Cause:** Screenshots too small, or wrong language model
- **Solution:** Increase screenshot resolution, verify OCR language setting
- **Check:** Manually review a few screenshots to confirm they're readable

### **Problem: PDF is 500MB+ (too large)**
- **Cause:** Too many images, or quality too high
- **Solution:** Reduce JPEG quality to 70-75, or reduce screenshots per session to 5
- **Tradeoff:** Lower quality = less readable text when zoomed

### **Problem: Sessions missing from catalog**
- **Cause:** Pagination not handled, or sessions filtered incorrectly
- **Solution:** Check for "Load More" button, or increase scroll depth
- **Check:** Compare total count from scraper vs conference website

### **Problem: Auth expires during long scraping**
- **Cause:** Session timeout, or short-lived tokens
- **Solution:** Refresh auth every 30 minutes, or use long-lived service account
- **Check:** Monitor for 401 responses in Playwright logs

---

## Extensions & Future Work

**Ideas for enhancing the skill:**

1. **Multi-language support:**
   - Detect conference language, use appropriate OCR model
   - Translate summaries to multiple languages

2. **Video transcript integration:**
   - Use conference-provided transcripts (if available)
   - Run speech-to-text on videos for more accurate content

3. **Interactive HTML version:**
   - Keep HTML as browsable website (not just PDF source)
   - Add filters by category, speaker, product
   - Search functionality for topics/products

4. **Speaker photos:**
   - Scrape speaker headshots from conference site
   - Include in Speaker Directory appendix

5. **Social media integration:**
   - Extract session hashtags, Twitter discussions
   - Include "Community Reaction" section per session

6. **Diff between conference years:**
   - Compare Book of News 2025 vs 2026
   - Highlight new products, discontinued features

7. **Auto-publishing pipeline:**
   - Generate daily/weekly updates during multi-day conferences
   - Email to subscribers, post to SharePoint

8. **Custom branding:**
   - Support custom cover designs, logos, color schemes
   - White-label for company internal conferences

---

## License & Attribution

This skill was developed from the MVP Summit 2026 Book of News project. It is designed to be reusable for any conference with recorded sessions.

**Attribution:** When sharing Book of News PDFs generated with this skill, include:
- "Generated with automated conference documentation pipeline"
- Link to source conference website
- Date of generation

**Disclaimer:** This skill is for educational and archival purposes. Respect conference terms of service and video distribution policies. Some conferences prohibit automated scraping or redistribution of recorded content.

---

## Contact & Support

For questions or contributions:
- Squad repo: `.squad/skills/conference-book-of-news-SKILL.md`
- Lead maintainer: Check `.squad/team.md` for current ownership
- Issues: File in squad backlog with `skill:conference-book-of-news` label
