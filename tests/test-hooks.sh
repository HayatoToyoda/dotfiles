#!/bin/bash
# Attack/normal-case matrix for the PreToolUse safety hooks.
# Exits non-zero if any case deviates from the expected decision.
set -u

cd "$(dirname "$0")/.."
FAILS=0

t() { # t <hook> <BLOCK|PASS> <command>
  local hook="$1" expect="$2" cmd="$3" out got
  out=$(printf '{"tool_input":{"command":%s},"cwd":"/tmp"}' \
    "$(printf '%s' "$cmd" | jq -Rs .)" | bash ".claude/hooks/$hook" 2>&1) || true
  if printf '%s' "$out" | grep -q '"deny"'; then got=BLOCK; else got=PASS; fi
  if [ "$got" = "$expect" ]; then
    echo "ok   [$expect] $cmd"
  else
    echo "FAIL [want $expect got $got] $cmd"
    FAILS=$((FAILS + 1))
  fi
}

echo "--- block-dangerous-bash.sh ---"
t block-dangerous-bash.sh BLOCK 'rm -rf /tmp/x'
t block-dangerous-bash.sh BLOCK 'rm -fr node_modules'
t block-dangerous-bash.sh BLOCK 'rm -r -f build'
t block-dangerous-bash.sh BLOCK 'rm --recursive --force dist'
t block-dangerous-bash.sh BLOCK 'sudo rm -rf /'
t block-dangerous-bash.sh BLOCK 'git reset --hard HEAD~1'
t block-dangerous-bash.sh BLOCK 'git clean -fdx'
t block-dangerous-bash.sh BLOCK 'git push --force origin main'
t block-dangerous-bash.sh BLOCK 'git push origin feature/x -f'
t block-dangerous-bash.sh BLOCK 'git commit --amend -m x'
t block-dangerous-bash.sh BLOCK 'git branch -D feature/x'
t block-dangerous-bash.sh BLOCK 'chmod 777 secret'
t block-dangerous-bash.sh BLOCK 'dd of=/dev/sda bs=1M'
t block-dangerous-bash.sh BLOCK 'mkfs.ext4 /dev/sdb1'
t block-dangerous-bash.sh PASS  'rm -f file.txt'
t block-dangerous-bash.sh PASS  'rm -r emptydir'
t block-dangerous-bash.sh PASS  'git commit -m "msg"'
t block-dangerous-bash.sh PASS  'git push origin feature/x'
t block-dangerous-bash.sh PASS  'npm run format'
t block-dangerous-bash.sh PASS  'dd if=/dev/urandom of=./rand.bin count=1'
t block-dangerous-bash.sh PASS  'chmod +x script.sh'

echo "--- check-main-push.sh ---"
t check-main-push.sh BLOCK 'git push origin main'
t check-main-push.sh BLOCK 'git push -u origin main'
t check-main-push.sh BLOCK 'git push origin HEAD:main'
t check-main-push.sh BLOCK 'git push origin feature/x:main'
t check-main-push.sh BLOCK 'echo hi; git push origin master'
t check-main-push.sh BLOCK 'npm test && git push origin main'
t check-main-push.sh PASS  'git push origin feature/x'
t check-main-push.sh PASS  'git push -u origin claude/foo'
t check-main-push.sh PASS  'git stash push -m wip'
t check-main-push.sh PASS  'git push origin main:feature/backup'
t check-main-push.sh PASS  'git push --force-with-lease origin feature/x'

echo
if [ "$FAILS" -gt 0 ]; then
  echo "$FAILS case(s) failed"
  exit 1
fi
echo "all cases passed"
