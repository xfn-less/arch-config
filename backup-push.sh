#!/bin/sh
# 手动备份：看 arch-config / arch-work 状况，确认后再 commit + push（全部改动含新文件）。
set -eu

repos='/home/xfn/arch-config /home/xfn/arch-work'

for repo in $repos; do
	printf '\n======== %s ========\n' "$repo"
	git -C "$repo" status -sb
	git -C "$repo" diff --stat
	git -C "$repo" diff --cached --stat
	if git -C "$repo" rev-parse '@{u}' >/dev/null 2>&1; then
		ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD')
		behind=$(git -C "$repo" rev-list --count 'HEAD..@{u}')
		printf 'upstream: ahead %s, behind %s\n' "$ahead" "$behind"
	else
		printf 'upstream: (none)\n'
	fi
done

printf '\n将暂存全部改动（含新文件，git add -A）。\n'
printf '确认对上述仓库执行 commit + push？[y/N] '
read -r ans
case $ans in
y | Y | yes | YES) ;;
*)
	printf '已取消。\n'
	exit 0
	;;
esac

for repo in $repos; do
	git -C "$repo" add -A
	if ! git -C "$repo" diff --cached --quiet; then
		git -C "$repo" commit -m "backup $(date -u +%Y-%m-%dT%H:%MZ)"
		printf 'committed %s\n' "$repo"
	else
		printf 'no changes %s\n' "$repo"
	fi
	if git -C "$repo" rev-parse '@{u}' >/dev/null 2>&1; then
		ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD')
		if [ "$ahead" -gt 0 ]; then
			git -C "$repo" push origin HEAD
			printf 'pushed %s\n' "$repo"
		fi
	fi
done
