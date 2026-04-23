# Skill: Nutrient Document Processing API

## Trigger

Use when writing or reviewing code that calls the Nutrient API (formerly PSPDFKit Server / PSPDFKit Document Engine) for PDF operations: merge, split, compress, convert, annotate, OCR, watermark, form filling, or digital signatures.

## Pre-Implementation Checklist

Before writing Nutrient API code:
- [ ] Confirm `NUTRIENT_API_KEY` is in the environment — never hardcode.
- [ ] Identify the operation type: synchronous (returns document directly) or async job (returns a job ID, poll for result).
- [ ] Check file size — the API has per-request payload limits (~100 MB); use multipart for large files.
- [ ] Plan retry logic for 429 (rate limit) and 503 (service unavailable) responses.
- [ ] Understand pricing: each API call consumes credits — batch operations in one request where possible.

## Process

### 1. Authentication

All requests use `Authorization: Bearer <API_KEY>` header. The base URL depends on whether you are using the cloud API or a self-hosted Document Engine.

```python
import os
import requests

NUTRIENT_API_KEY = os.environ["NUTRIENT_API_KEY"]
NUTRIENT_BASE_URL = "https://api.nutrient.io/v1"   # cloud

HEADERS = {
    "Authorization": f"Bearer {NUTRIENT_API_KEY}",
}

# Test auth
resp = requests.get(f"{NUTRIENT_BASE_URL}/me", headers=HEADERS)
resp.raise_for_status()
print(resp.json())
```

Self-hosted Document Engine uses HTTP Basic auth:

```python
# Self-hosted
import base64
creds = base64.b64encode(b"admin:password").decode()
HEADERS = {"Authorization": f"Basic {creds}"}
```

### 2. PDF merge

```python
def merge_pdfs(pdf_paths: list[str], output_path: str) -> None:
    """Merge multiple PDFs into one, in order."""
    files = []
    try:
        for i, path in enumerate(pdf_paths):
            files.append((f"file_{i}", open(path, "rb")))

        instructions = {
            "parts": [
                {"file": f"file_{i}"} for i in range(len(pdf_paths))
            ]
        }

        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files=files,
            data={"instructions": str(instructions).replace("'", '"')},  # must be JSON string
        )
        resp.raise_for_status()

        with open(output_path, "wb") as out:
            out.write(resp.content)
    finally:
        for _, f in files:
            f.close()
```

Using curl for quick operations:

```bash
curl -X POST https://api.nutrient.io/v1/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "file_0=@invoice.pdf" \
  -F "file_1=@appendix.pdf" \
  -F 'instructions={"parts":[{"file":"file_0"},{"file":"file_1"}]}' \
  -o merged.pdf
```

### 3. PDF split

```python
def split_pdf(pdf_path: str, output_dir: str, page_ranges: list[tuple[int, int]]) -> list[str]:
    """Split a PDF into segments by page range. Pages are 1-indexed."""
    output_paths = []
    with open(pdf_path, "rb") as f:
        pdf_bytes = f.read()

    for i, (start, end) in enumerate(page_ranges):
        instructions = {
            "parts": [{"file": "document", "pages": {"start": start, "end": end}}]
        }
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": pdf_bytes},
            data={"instructions": json.dumps(instructions)},
        )
        resp.raise_for_status()

        out_path = os.path.join(output_dir, f"part_{i+1}.pdf")
        with open(out_path, "wb") as out:
            out.write(resp.content)
        output_paths.append(out_path)

    return output_paths
```

### 4. Compress PDF

```python
def compress_pdf(input_path: str, output_path: str, preset: str = "default") -> int:
    """
    Compress a PDF. Presets: 'default', 'low', 'high'.
    Returns output file size in bytes.
    """
    instructions = {
        "parts": [{"file": "document"}],
        "output": {"type": "pdf", "compress": {"preset": preset}}
    }
    with open(input_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()

    with open(output_path, "wb") as out:
        out.write(resp.content)

    return len(resp.content)
```

### 5. Convert: Office → PDF, PDF → image

```bash
# Word to PDF
curl -X POST https://api.nutrient.io/v1/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document=@report.docx" \
  -F 'instructions={"parts":[{"file":"document"}],"output":{"type":"pdf"}}' \
  -o report.pdf

# PDF page to PNG (page 1)
curl -X POST https://api.nutrient.io/v1/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document=@report.pdf" \
  -F 'instructions={"parts":[{"file":"document","pages":{"start":1,"end":1}}],"output":{"type":"image","format":"png","dpi":150}}' \
  -o page1.png
```

```python
# Python — convert and return bytes
def pdf_to_images(pdf_path: str, dpi: int = 150) -> bytes:
    instructions = {
        "parts": [{"file": "document"}],
        "output": {"type": "image", "format": "png", "dpi": dpi}
    }
    with open(pdf_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()
    return resp.content   # ZIP archive of PNG files
```

### 6. OCR for scanned documents

```python
def ocr_pdf(input_path: str, output_path: str, language: str = "english") -> None:
    """Run OCR on a scanned PDF to make text selectable/searchable."""
    instructions = {
        "parts": [{"file": "document"}],
        "output": {
            "type": "pdf",
            "optimize": True,
        },
        "actions": [{"type": "ocr", "language": language}]
    }
    with open(input_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()

    with open(output_path, "wb") as out:
        out.write(resp.content)
```

Supported OCR languages (partial): `english`, `french`, `german`, `spanish`, `arabic`, `chinese-simplified`.

### 7. Form field filling

```python
def fill_form(template_path: str, output_path: str, field_values: dict[str, str]) -> None:
    """Fill PDF form fields programmatically."""
    form_fields = [
        {"name": name, "value": value}
        for name, value in field_values.items()
    ]
    instructions = {
        "parts": [{"file": "form"}],
        "actions": [{"type": "fillForm", "formFields": form_fields}]
    }
    with open(template_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"form": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()

    with open(output_path, "wb") as out:
        out.write(resp.content)

# Usage
fill_form(
    "invoice_template.pdf",
    "invoice_001.pdf",
    {
        "customer_name": "Acme Corp",
        "invoice_number": "INV-001",
        "total": "$1,250.00",
    }
)
```

### 8. Watermarking

```python
def add_watermark(input_path: str, output_path: str, text: str, opacity: float = 0.3) -> None:
    instructions = {
        "parts": [{"file": "document"}],
        "actions": [{
            "type": "watermark",
            "text": text,
            "opacity": opacity,
            "rotation": 45,
            "fontSize": 48,
            "fontColor": "#FF0000",
            "position": {"type": "center"},
        }]
    }
    with open(input_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()

    with open(output_path, "wb") as out:
        out.write(resp.content)
```

### 9. Webhook callbacks for async jobs

Long operations (large OCR, complex builds) return a job ID. Configure a webhook to receive the result.

```python
def submit_async_job(pdf_path: str, webhook_url: str) -> str:
    """Submit an async job. Returns job_id."""
    instructions = {
        "parts": [{"file": "document"}],
        "actions": [{"type": "ocr", "language": "english"}],
        "webhook": {"url": webhook_url}
    }
    with open(pdf_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build/async",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()
    return resp.json()["job_id"]

# Webhook handler (Flask example)
from flask import Flask, request
app = Flask(__name__)

@app.post("/nutrient-webhook")
def handle_webhook():
    payload = request.json
    job_id = payload["job_id"]
    status = payload["status"]   # "completed" or "failed"

    if status == "completed":
        download_url = payload["result"]["download_url"]
        # Fetch and store the result
        result = requests.get(download_url, headers=HEADERS)
        with open(f"result_{job_id}.pdf", "wb") as f:
            f.write(result.content)
    elif status == "failed":
        print(f"Job {job_id} failed: {payload.get('error')}")

    return "", 200
```

### 10. Error handling and retry logic

```python
import time
import json

class NutrientClient:
    def __init__(self, api_key: str, base_url: str = "https://api.nutrient.io/v1"):
        self.headers = {"Authorization": f"Bearer {api_key}"}
        self.base_url = base_url

    def build(self, files: dict, instructions: dict, max_retries: int = 3) -> bytes:
        for attempt in range(max_retries):
            try:
                resp = requests.post(
                    f"{self.base_url}/build",
                    headers=self.headers,
                    files={k: v for k, v in files.items()},
                    data={"instructions": json.dumps(instructions)},
                    timeout=120,
                )

                if resp.status_code == 429:
                    retry_after = int(resp.headers.get("Retry-After", 2 ** attempt))
                    time.sleep(retry_after)
                    continue

                if resp.status_code == 503:
                    time.sleep(2 ** attempt)
                    continue

                if resp.status_code == 422:
                    # Unprocessable — bad instructions, do not retry
                    raise ValueError(f"Invalid instructions: {resp.json()}")

                resp.raise_for_status()
                return resp.content

            except requests.Timeout:
                if attempt == max_retries - 1:
                    raise
                time.sleep(2 ** attempt)

        raise RuntimeError(f"Operation failed after {max_retries} attempts")
```

### 11. Annotation extraction

```python
def extract_annotations(pdf_path: str) -> list[dict]:
    """Extract all annotations from a PDF as JSON."""
    instructions = {
        "parts": [{"file": "document"}],
        "output": {"type": "json-annotations"}
    }
    with open(pdf_path, "rb") as f:
        resp = requests.post(
            f"{NUTRIENT_BASE_URL}/build",
            headers=HEADERS,
            files={"document": f},
            data={"instructions": json.dumps(instructions)},
        )
    resp.raise_for_status()
    return resp.json().get("annotations", [])
```

## Pricing Considerations

| Operation | Credit cost (approximate) |
|-----------|--------------------------|
| Merge/split/compress | 1 credit per output page |
| OCR | 2 credits per page |
| Office → PDF conversion | 1 credit per page |
| Form filling | 1 credit per page |
| Digital signature | 5 credits per document |

Batch pages in one `/build` call rather than multiple calls — saves both credits and latency.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| Hardcoded API key | Security leak | `os.environ["NUTRIENT_API_KEY"]` |
| No retry on 429 | Silent failure under load | Exponential backoff with `Retry-After` |
| Separate API calls for each merge | 10× credit cost | Single `/build` with multiple parts |
| No timeout on requests | Hangs indefinitely | `timeout=120` on all requests |
| Storing webhook payload without verification | Spoofable webhooks | Verify signature header if Nutrient provides HMAC |
| Not closing file handles | File descriptor leak | `with open(...)` or explicit `finally` |
| Ignoring 422 responses | Silent wrong output | Parse and raise on 422 — it is a logic error |
| Passing instructions as Python dict str() | `'single quotes'` breaks JSON parsing | Always `json.dumps(instructions)` |

## Safe Behavior

- Does not log document contents — PDFs may contain sensitive data.
- Does not approve its own output.
- API key handling must use environment variables — flagged as CRITICAL if hardcoded.
- Operations on documents containing PII (passports, medical, financial) require Ahmed's explicit approval before automation.
- Webhook endpoints must be authenticated — flagged as HIGH if unauthenticated.
