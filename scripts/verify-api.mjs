import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

function listFiles(dir) {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? listFiles(path) : [path];
  });
}

const apiFiles = listFiles("api").filter((file) => file.endsWith(".js"));
if (apiFiles.length === 0) {
  throw new Error("No API routes found.");
}

console.log(`Verified ${apiFiles.length} API routes.`);
