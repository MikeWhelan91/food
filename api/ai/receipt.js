import { generateShelfJSON, handleError, readJSONBody, requirePost, sendJSON } from "../_lib/openai.js";

export default async function handler(request, response) {
  if (!requirePost(request, response)) {
    return;
  }

  try {
    await readJSONBody(request);
    const result = await generateShelfJSON(`
Create a realistic grocery receipt extraction result.
Return JSON with this exact shape:
{"items":[{"name":"Milk","quantity":1,"category":"Fridge","confidence":0.94}]}
Include 4 to 7 common grocery products. Categories must be one of Fridge, Freezer, Pantry, Bathroom, Cleaning, Pet.
`);

    sendJSON(response, 200, normalizeReceiptPayload(result));
  } catch (error) {
    handleError(response, error);
  }
}

function normalizeReceiptPayload(payload) {
  if (!Array.isArray(payload.items)) {
    return { items: [] };
  }
  return {
    items: payload.items.slice(0, 12).map((item) => ({
      name: String(item.name || "Unknown item"),
      quantity: Number(item.quantity || 1),
      category: String(item.category || "Pantry"),
      confidence: clampNumber(item.confidence, 0, 1, 0.75)
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
