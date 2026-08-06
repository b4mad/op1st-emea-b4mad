#!/usr/bin/env bash
#
# anubis-smoke.sh — prove that the Anubis sidecar in front of #B4mad Forge
# actually challenges browsers, denies AI scrapers, and stays out of the way of
# git/registry/feed clients.
#
# Policy lives in manifests/applications/b4mad-forgejo/anubis.yaml. This script
# is the black-box counterpart: it drives the PUBLIC route with a matrix of
# user agents and asserts the verdict Anubis reaches for each one.
#
# ⚠️ The HTTP status code is NOT the signal. Anubis v1.26.x answers 200 for all
# three verdicts; what differs is the page it serves. So we classify on the
# body:
#
#   deny       "Oh noes!"                   — request refused
#   challenge  "not a bot"                  — proof-of-work interstitial
#   allow      anything else (Forgejo)      — proxied straight through
#
# Usage:  scripts/anubis-smoke.sh [base-url]
# Exit:   0 all cases matched, 1 otherwise.
set -uo pipefail

BASE="${1:-https://git.b4mad.industries}"
CURL=(curl -sS --max-time 20 --compressed)

FIREFOX='Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0'

fail=0

# classify <user-agent> <path> -> allow|challenge|deny|error
classify() {
  local body
  body="$("${CURL[@]}" -A "$1" "$BASE$2" 2>/dev/null)" || { echo error; return; }
  case "$body" in
    *"Oh noes!"*) echo deny ;;
    *"not a bot"*) echo challenge ;;
    "") echo error ;;
    *) echo allow ;;
  esac
}

# check <expected> <label> <user-agent> [path]
check() {
  local want="$1" label="$2" ua="$3" path="${4:-/explore/repos}" got
  got="$(classify "$ua" "$path")"
  if [[ "$got" == "$want" ]]; then
    printf '  ok   %-34s %s\n' "$label" "$got"
  else
    printf '  FAIL %-34s want %-9s got %s\n' "$label" "$want" "$got"
    fail=1
  fi
}

echo "Anubis smoke test against $BASE"

echo "-- humans must work for it"
check challenge "Firefox"                "$FIREFOX"
check challenge "Chrome"                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'

echo "-- named AI scrapers are refused"
check deny "GPTBot"                      'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; GPTBot/1.2; +https://openai.com/gptbot'
check deny "ClaudeBot"                   'Mozilla/5.0 (compatible; ClaudeBot/1.0; +claudebot@anthropic.com)'
check deny "PerplexityBot"               'Mozilla/5.0 (compatible; PerplexityBot/1.0; +https://perplexity.ai/perplexitybot)'
check deny "Bytespider"                  'Mozilla/5.0 (compatible; Bytespider; spider-feedback@bytedance.com)'
check deny "meta-externalagent"          'meta-externalagent/1.1'
check deny "Amazonbot"                   'Mozilla/5.0 (compatible; Amazonbot/0.1; +https://developer.amazon.com/support/amazonbot)'
check deny "Scrapy"                      'Scrapy/2.11 (+https://scrapy.org)'
# Non-Mozilla agents: the class that used to walk straight in, because Anubis
# only challenges "Mozilla" and default-allows the rest. Covered by the
# `robots-txt-ai-agents` DENY rule in anubis.yaml (op1st-emea-b4mad-las).
check deny "CCBot (CommonCrawl, no Mozilla)" 'CCBot/2.0 (https://commoncrawl.org/faq/)'
check deny "img2dataset"                 'img2dataset'
check deny "Timpibot"                    'Timpibot/0.9'

echo "-- opt-out crawlers named in robots.txt"
check deny "Google-Extended"             'Mozilla/5.0 (compatible; Google-Extended/1.0)'
check deny "Applebot-Extended"           'Mozilla/5.0 (compatible; Applebot-Extended/0.1)'
check deny "facebookexternalhit"         'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)'
check deny "PetalBot"                    'Mozilla/5.0 (compatible; PetalBot; +https://webmaster.petalsearch.com/site/petalbot)'

echo "-- search engines we DO want must not be caught by that rule"
# ⚠️ Expected verdict is `challenge`, not `allow`: (data)/crawlers/_allow-good.yaml
# gates Googlebot on Google's address ranges, so a spoofed UA from a random IP
# is correctly NOT allowed. What this case proves is that it is not DENYed —
# i.e. `Google-Extended|GoogleOther` in the deny regex does not catch Googlebot.
# From inside Google's ranges the real crawler gets `allow`.
check challenge "Googlebot (spoofed UA)" 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
check challenge "Bingbot (spoofed UA)"   'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)'

echo "-- machine clients must never see an interstitial"
check allow "git"                        'git/2.45.2'
check allow "libgit2"                    'libgit2/1.7.2'
check allow "JGit"                       'JGit/6.9'
check allow "curl"                       'curl/8.9.1'
check allow "docker registry /v2/"       'docker/24.0.7 go/go1.20 kernel/6.1 os/linux' '/v2/'
check allow "skopeo /v2/"                'skopeo/1.15.0' '/v2/'

echo "-- keep-internet-working paths (browser UA, must still pass)"
check allow "robots.txt"                 "$FIREFOX" '/robots.txt'
check allow "favicon"                    "$FIREFOX" '/favicon.ico'
check allow "atom feed"                  "$FIREFOX" '/explore/repos.atom'

# A real git client, not a spoofed user agent — this is the case that breaks
# loudly for every user if the git.yaml allow-import is ever dropped.
# GIT_REPO must be a PUBLIC repo with at least one ref.
GIT_REPO="${GIT_REPO:-goern/.profile}"
echo "-- git over the public route actually completes"
if git -c protocol.version=2 ls-remote "$BASE/$GIT_REPO.git" 2>/dev/null | grep -q .; then
  printf '  ok   %-34s refs returned\n' "git ls-remote $GIT_REPO"
else
  printf '  FAIL %-34s no refs (auth? empty repo? Anubis?)\n' "git ls-remote $GIT_REPO"
  fail=1
fi

echo
if [[ $fail -eq 0 ]]; then
  echo "PASS — Anubis is enforcing the policy in anubis.yaml"
else
  echo "FAIL — see cases above; policy is in manifests/applications/b4mad-forgejo/anubis.yaml"
fi
exit $fail
