import { generateShelfJSON, handleError, readJSONBody, requirePost, sendJSON } from "../_lib/openai.js";

export default async function handler(request, response) {
  if (!requirePost(request, response)) {
    return;
  }

  try {
    await readJSONBody(request);
    const result = await generateShelfJSON(`
Create a realistic OCR expiry extraction result from grocery packaging.
Return JSON with this exact shape:
{"label":"Best Before","expiryDaysFromNow":4,"rawText":"BEST BEFORE 21 MAY","confidence":0.82}
Label must be Use By, Best Before, or Expires.
`);

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
