import assert from "node:assert";
import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { printCursorPostInstallChecklist } from "./install-config-helper.mjs";

function captureStdout(fn) {
  const chunks = [];
  const original = process.stdout.write.bind(process.stdout);
  process.stdout.write = (chunk, ...args) => {
    chunks.push(String(chunk));
    return original(chunk, ...args);
  };
  try {
    fn();
  } finally {
    process.stdout.write = original;
  }
  return chunks.join("");
}

test("printCursorPostInstallChecklist references serverName", () => {
  const output = captureStdout(() => {
    printCursorPostInstallChecklist("/tmp/mcp.json", {}, "cursor-computer-use");
  });
  assert.match(output, /cursor-computer-use/);
  assert.match(output, /Post-install checklist/);
  assert.match(output, /open-computer-use doctor --cursor/);
});

test("cursor-mcp idempotent install prints checklist", () => {
  const dir = mkdtempSync(path.join(tmpdir(), "cursor-mcp-test-"));
  const configPath = path.join(dir, "mcp.json");
  writeFileSync(
    configPath,
    JSON.stringify({
      mcpServers: {
        "cursor-computer-use": { command: "open-computer-use", args: ["mcp"] },
      },
    }),
    "utf8",
  );

  const scriptPath = fileURLToPath(new URL("./install-config-helper.mjs", import.meta.url));
  const output = execFileSync(
    process.execPath,
    [scriptPath, "cursor-mcp", configPath, "cursor-computer-use", "open-computer-use"],
    { encoding: "utf8", cwd: dir },
  );
  assert.match(output, /already installed/);
  assert.match(output, /Post-install checklist/);
  assert.match(output, /cursor-computer-use/);
});
