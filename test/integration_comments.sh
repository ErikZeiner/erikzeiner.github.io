#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
tmp_override="${tmp_dir}/comments-test-override.yml"
tmp_site="${tmp_dir}/site"
giscus_post="_posts/2026-01-01-integration-giscus-comments.md"
disqus_post="_posts/2026-01-02-integration-disqus-comments.md"

cleanup() {
  rm -rf "${tmp_dir}"
  rm -f "${giscus_post}" "${disqus_post}"
  rmdir _posts 2>/dev/null || true
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
cat >"${giscus_post}" <<'POST'
---
layout: post
title: Integration Giscus Comments
date: 2026-01-01 00:00:00
giscus_comments: true
---
giscus integration test fixture
POST

cat >"${disqus_post}" <<'POST'
---
layout: post
title: Integration Disqus Comments
date: 2026-01-02 00:00:00
disqus_comments: true
---
disqus integration test fixture
POST

bundle exec jekyll build --config "_config.yml,${tmp_override}" -d "${tmp_site}" >/dev/null

giscus_page="${tmp_site}/blog/2026/integration-giscus-comments/index.html"
disqus_page="${tmp_site}/blog/2026/integration-disqus-comments/index.html"

if [ ! -f "${giscus_page}" ]; then
  echo "giscus integration page was not generated at ${giscus_page}" >&2
  exit 1
fi

grep -q 'https://giscus.app/client.js' "${giscus_page}"
if grep -q 'giscus comments misconfigured' "${giscus_page}"; then
  echo "unexpected giscus misconfiguration warning in ${giscus_page}" >&2
  exit 1
fi

if [ ! -f "${disqus_page}" ]; then
  echo "disqus integration page was not generated at ${disqus_page}" >&2
  exit 1
fi

grep -q 'id="disqus_thread"' "${disqus_page}"
grep -q '.disqus.com/embed.js' "${disqus_page}"

echo "comments integration checks passed"
