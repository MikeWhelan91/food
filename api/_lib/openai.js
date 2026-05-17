const DEFAULT_MODEL = "gpt-4.1-mini";

export function setJSONHeaders(response, status = 200) {
  response.statusCode = status;
  response.setHeader("Content-Type", "application/json");
  response.setHeader("Cache-Control", "no-store");
}

export function sendJSON(response, status, payload) {
  setJSONHeaders(response, status);
  response.end(JSON.stringify(payload));
}

export async function readJSONBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) {
    return {};
  }

  const rawBody = Buffer.concat(chunks).toString("utf8");
  if (!rawBody.trim()) {
    return {};
  }

  return JSON.parse(rawBody);
}

export function requirePost(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    sendJSON(response, 405, { error: "method_not_allowed" });
    return false;
  }
  return true;
}

export async function generateShelfJSON(prompt, maxOutputTokens = 900) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    const error = new Error("OPENAI_API_KEY is not configured.");
    error.statusCode = 500;
    error.code = "missing_openai_key";
    throw error;
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || DEFAULT_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text: "You extract household inventory data for Shelf. Return compact valid JSON only. Do not include prose or markdown."
            }
          ]
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: prompt
            }
          ]
        }
      ],
      temperature: 0.1,
      max_output_tokens: maxOutputTokens
    })
  });

  if (!response.ok) {
    const body = await response.text();
    const error = new Error(`OpenAI request failed with ${response.status}.`);
    error.statusCode = 502;
    error.code = "openai_request_failed";
    error.details = body.slice(0, 500);
    throw error;
  }

  const data = await response.json();
  const text = extractOutputText(data);
  if (!text) {
    const error = new Error("OpenAI response did not include text output.");
    error.statusCode = 502;
    error.code = "openai_empty_output";
    throw error;
  }

  return parseJSONText(text);
}

export function handleError(response, error) {
  const status = error.statusCode || 500;
  sendJSON(response, status, {
    error: error.code || "server_error",
    message: status >= 500 ? "The Shelf AI service is temporarily unavailable." : error.message
  });
}

function extractOutputText(data) {
  if (typeof data.output_text === "string") {
    return data.output_text.trim();
  }

  return (data.output || [])
    .flatMap((item) => item.content || [])
    .map((content) => content.text || "")
    .join("\n")
    .trim();
}

function parseJSONText(text) {
  const trimmed = text.trim();
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    return JSON.parse(trimmed);
  }

  const match = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (match) {
    return JSON.parse(match[1]);
  }

  throw Object.assign(new Error("Model returned non-JSON output."), {
    statusCode: 502,
    code: "invalid_model_json"
  });
}
