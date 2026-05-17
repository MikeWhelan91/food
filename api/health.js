import { sendJSON } from "./_lib/openai.js";

export default function handler(request, response) {
  sendJSON(response, 200, {
    ok: true,
    service: "shelf-api"
  });
}
