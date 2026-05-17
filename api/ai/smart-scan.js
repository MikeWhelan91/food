import { generateShelfJSON, handleError, readJSONBody, requirePost, sendJSON } from "../_lib/openai.js";

export default async function handler(request, response) {
  if (!requirePost(request, response)) {
    return;
  }

  try {
    const body = await readJSONBody(request);
    const imageCount = clampInteger(body.imageCount, 1, 3, 1);
    const result = await generateShelfJSON(`
Create a realistic fridge or pantry smart scan result for ${imageCount} captured image(s).
Return JSON with this exact shape:
{"items":[{"name":"Milk","brand":"Avonmore","quantity":1,"category":"Fridge","expiryDaysFromNow":3,"confidence":0.91,"imageSystemName":"carton"}]}
Use 3 to 6 common household grocery items. Categories must be one of Fridge, Freezer, Pantry, Bathroom, Cleaning, Pet.
`);

    sendJSON(response, 200, normalizeItemsPayload(result));
  } catch (error) {
    handleError(response, error);
  }
}

function clampInteger(value, min, max, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.min(Math.max(parsed, min), max);
}

function normalizeItemsPayload(payload) {
  if (!Array.isArray(payload.items)) {
    return { items: [] };
  }
  return {
    items: payload.items.slice(0, 8).map((item) => ({
      name: String(item.name || "Unknown item"),
      brand: String(item.brand || ""),
      quantity: Number(item.quantity || 1),
      category: String(item.category || "Pantry"),
      expiryDaysFromNow: item.expiryDaysFromNow == null ? null : Number(item.expiryDaysFromNow),
      confidence: clampNumber(item.confidence, 0, 1, 0.75),
      imageSystemName: String(item.imageSystemName || "takeoutbag.and.cup.and.straw")
    }))
  };
}

function clampNumber(value, min, max, fallback) {
  const parsed = Number(value);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.min(Math.max(parsed, min), max);
}
