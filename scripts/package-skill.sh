#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_skill() {
  local skill_name="$1"
  local skill_dir="${repo_root}/skills/${skill_name}"
  local dist_dir="${repo_root}/dist/skills"
  local zip_path="${dist_dir}/${skill_name}-skill.zip"
  local skill_path="${dist_dir}/${skill_name}.skill"

  if [[ ! -f "${skill_dir}/SKILL.md" ]]; then
    echo "missing skill entrypoint: ${skill_dir}/SKILL.md" >&2
    exit 1
  fi

  node - "${skill_dir}/SKILL.md" "${skill_name}" <<'NODE'
const fs = require("fs");

const skillPath = process.argv[2];
const skillName = process.argv[3];
const content = fs.readFileSync(skillPath, "utf8");
const errors = [];

if (!content.startsWith("---\n")) {
  errors.push("SKILL.md must start with YAML frontmatter");
}
if (!new RegExp(`^name:\\s*${skillName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\s*$`, "m").test(content)) {
  errors.push(`SKILL.md frontmatter must include name: ${skillName}`);
}
if (!/^description:\s*\S/m.test(content)) {
  errors.push("SKILL.md frontmatter must include a non-empty description");
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(error);
  }
  process.exit(1);
}
NODE

  mkdir -p "${dist_dir}"
  (
    cd "${repo_root}/skills"
    zip -q -r "${zip_path}" "${skill_name}"
  )
  cp "${zip_path}" "${skill_path}"

  echo "${zip_path}"
  echo "${skill_path}"
}

validate_skill_zip() {
  local skill_name="$1"
  local zip_path="${repo_root}/dist/skills/${skill_name}-skill.zip"
  local has_skill_entrypoint=0
  local entry_count=0

  while IFS= read -r entry; do
    entry_count=$((entry_count + 1))
    if [[ "${entry}" != "${skill_name}/"* ]]; then
      echo "skill zip entry must be under ${skill_name}/: ${entry}" >&2
      exit 1
    fi
    if [[ "${entry}" == "${skill_name}/SKILL.md" ]]; then
      has_skill_entrypoint=1
    fi
  done < <(unzip -Z1 "${zip_path}")

  if [[ "${entry_count}" -eq 0 ]]; then
    echo "skill zip is empty" >&2
    exit 1
  fi

  if [[ "${has_skill_entrypoint}" -ne 1 ]]; then
    echo "skill zip is missing ${skill_name}/SKILL.md" >&2
    exit 1
  fi
}

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to validate the skill package" >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "zip is required to package the skill" >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required to validate the skill package" >&2
  exit 1
fi

rm -rf "${repo_root}/dist/skills"
mkdir -p "${repo_root}/dist/skills"

package_skill "open-computer-use"
validate_skill_zip "open-computer-use"
package_skill "cursor-computer-use"
validate_skill_zip "cursor-computer-use"

manifest_path="${repo_root}/dist/skills/package-manifest.json"
node - "${manifest_path}" <<'NODE'
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const manifestPath = process.argv[2];
const distDir = path.dirname(manifestPath);
const skills = ["open-computer-use", "cursor-computer-use"];
const payload = { generatedAtUtc: new Date().toISOString(), skills: {} };

for (const name of skills) {
  const zipPath = path.join(distDir, `${name}-skill.zip`);
  const skillPath = path.join(distDir, `${name}.skill`);
  const zip = fs.readFileSync(zipPath);
  const skill = fs.readFileSync(skillPath);
  if (crypto.createHash("sha256").update(zip).digest("hex") !== crypto.createHash("sha256").update(skill).digest("hex")) {
    throw new Error(`${name}: zip and .skill differ`);
  }
  payload.skills[name] = {
    rootDirectory: name,
    artifacts: { zip: zipPath, skill: skillPath },
    sha256: {
      zip: crypto.createHash("sha256").update(zip).digest("hex"),
      skill: crypto.createHash("sha256").update(skill).digest("hex"),
    },
  };
}

fs.writeFileSync(manifestPath, `${JSON.stringify(payload, null, 2)}\n`);
NODE
