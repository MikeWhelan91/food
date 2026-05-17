import { generateShelfJSON, handleError, normalizeImages, readJSONBody, requirePost, sendJSON } from "../_lib/openai.js";

export default async function handler(request, response) {
  if (!requirePost(request, response)) {
    return;
  }

  try {
    const body = await readJSONBody(request);
    const images = normalizeImages(body.image ? [body.image] : []);
    const result = await generateShelfJSON(`
Analyze the attached packaging image and extract the visible expiry, use-by, best-before, or expires date. If no date is visible, return null for expiryDaysFromNow and low confidence.
Return JSON with this exact shape:
{"label":"Best Before","expiryDaysFromNow":4,"rawText":"BEST BEFORE 21 MAY","confidence":0.82}
Label must be Use By, Best Before, or Expires.
`, 650, images);

    sendJSON(response, 200, {
      label: String(result.label || "Best Before"),
      expiryDaysFromNow: result.expiryDaysFromNow == null ? null : Number(result.expiryDaysFromNow),
      rawText: String(result.rawText || ""),
      confidence: clampNumber(result.confidence, 0, 1, 0.75)
    });
  } catch (error) {
    handleError(response, error);
  }
}

function clampNumber(value, min, max, fallback) {
  const parsed = Number(value);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.min(Math.max(parsed, min), max);
}
