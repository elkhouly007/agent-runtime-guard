# Visa Document Translation

Help translate visa application documents into professional English while preserving structure, names, dates, and amounts accurately.

## Trigger

Use when:
- the user needs a visa-supporting document translated into English,
- an image or scan must be OCR'd before translation,
- document formatting should be preserved for submission or review,
- a bilingual or translated PDF deliverable is needed.

## Instructions

When the user provides a document image or scan, follow this workflow carefully and safely:

1. **Image Conversion**
   - If the file is HEIC, convert it to PNG or another OCR-friendly format.

2. **Image Rotation**
   - Check EXIF orientation data when available.
   - Rotate the image to make the document upright and readable.
   - If orientation remains ambiguous, verify visually before proceeding.

3. **OCR Text Extraction**
   - Try one or more OCR methods appropriate to the host environment.
   - Extract all visible text from the document.
   - Identify the likely document type, such as deposit certificate, employment certificate, or retirement certificate.

4. **Translation**
   - Translate all text content to professional English.
   - Maintain the original document structure and hierarchy as closely as possible.
   - Use terminology appropriate for immigration and visa contexts.
   - Keep proper names in the original language with English clarification where useful.
   - Preserve all numbers, dates, identifiers, and amounts accurately.

5. **Output Packaging**
   - If needed, prepare a clean translated PDF or side-by-side output.
   - Clearly label the document as a translation unless the user provides their own certification wording.
   - Avoid implying official certification unless the user explicitly requests and supplies the required legal phrasing.
