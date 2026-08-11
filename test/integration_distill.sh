#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
tmp_override="${tmp_dir}/distill-override.yml"
tmp_site="${tmp_dir}/site"
tmp_post="_posts/2026-01-03-integration-distill.md"

declare -r distill_title="Integration Distill Test"
declare -r distill_date="2026-01-03 00:00:00"
declare -r distill_slug="integration-distill"

cleanup() {
  rm -rf "${tmp_dir}"
  rm -f "${tmp_post}"
}
trap cleanup EXIT

cat >"${tmp_override}" <<'YAML'
giscus:
  repo: alshedivat/al-folio
  repo_id: R_kgDOExample
  category: Comments
  category_id: DIC_kwDOExample
external_sources: []
YAML

mkdir -p _posts
cat >"${tmp_post}" <<'POST'
---
layout: distill
title: Integration Distill Test
date: 2026-01-03 00:00:00
permalink: /blog/2026/integration-distill/
---

<d-front-matter>
  <script type="application/json">
    {"title":"Integration Distill Test","description":"Integration fixture for distill rendering checks"}
  </script>
</d-front-matter>

<d-article>
  <h1>Integration Distill Test</h1>
  <p>This fixture exists only for the distill integration check.</p>
</d-article>
POST

bundle exec jekyll build --config "_config.yml,${tmp_override}" -d "${tmp_site}" >/dev/null

distill_page="${tmp_site}/blog/2026/integration-distill/index.html"

if [ ! -f "${distill_page}" ]; then
  echo "distill page was not generated at ${distill_page}" >&2
  exit 1
fi

grep -q 'd-front-matter' "${distill_page}"
grep -q '/assets/js/distillpub/template.v2.js' "${distill_page}"
grep -q '/assets/js/distillpub/transforms.v2.js' "${distill_page}"
grep -q '/assets/js/distillpub/overrides.js' "${distill_page}"
grep -q '/assets/al_charts/js/mermaid-setup.js' "${distill_page}"
grep -q 'https://cdn.jsdelivr.net/npm/@planktimerr/tikzjax@1.0.8/dist/fonts.css' "${distill_page}"
grep -q 'https://cdn.jsdelivr.net/npm/@planktimerr/tikzjax@1.0.8/dist/tikzjax.js' "${distill_page}"
grep -q 'id="giscus_thread"' "${distill_page}"
transforms_runtime="${tmp_site}/assets/js/distillpub/transforms.v2.js"
distill_runtime="$(PATH="$HOME/.rbenv/shims:$PATH" bundle exec ruby -e 'spec = Gem.loaded_specs["al_folio_distill"]; puts(spec ? File.join(spec.full_gem_path, "assets/js/distillpub/transforms.v2.js") : "")')"
if [ -f "${distill_runtime}" ]; then
  # Prefer the packaged gem runtime for deterministic parity checks.
  transforms_runtime="${distill_runtime}"
elif [ ! -f "${transforms_runtime}" ]; then
  echo "distill transforms runtime missing at ${transforms_runtime} (and not found in installed al_folio_distill gem)" >&2
  exit 1
fi

expected_transforms_hash="5d85590f5652b910ab2411019749c83ef5a5a3fbb9b739adc92b4557b6bf3d39"
actual_transforms_hash="$(ruby -rdigest -e 'print Digest::SHA256.file(ARGV[0]).hexdigest' "${transforms_runtime}")"
if [ "${actual_transforms_hash}" != "${expected_transforms_hash}" ]; then
  echo "unexpected distill transforms runtime hash: ${actual_transforms_hash}" >&2
  exit 1
fi

echo "distill integration checks passed"
