[[ $- == *i* ]] || return

PS1='\[\e[1m\]\A \W\$ \[\e[0m\]'

. /usr/share/bash-completion/bash_completion
eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS='--style minimal --layout reverse --info inline --exact --preview-window=right,50%,wrap'
_fzf_preview='
	case $(file --mime-type -b {}) in
		image/*) chafa -f symbols -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" {} ;;
		inode/directory) ls -la --color=always {} ;;
		text/*|*/xml|*/json|*/javascript) sed -n "1,120p" {} ;;
		*) file {} ;;
	esac
'
export FZF_CTRL_T_OPTS="--preview '$_fzf_preview' --preview-window right,50%,noborder"
export FZF_COMPLETION_OPTS="--preview '$_fzf_preview' --preview-window right,50%,noborder"
export FZF_ALT_C_OPTS="--preview 'ls -la --color=always {}' --preview-window right,50%,noborder"
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort'"
unset _fzf_preview

set -o noclobber

export EDITOR=vis VISUAL=vis

alias ld='ls -Alh --color=auto'
alias gl='git clone --depth=1'

# Tab 多选，Enter 执行；Esc 取消。安装/删除保留 pacman、paru 的确认。
pacr() {
	awk '
		FNR == 1 { reason = 0 }
		/^%NAME%$/ { getline; name = $0 }
		/^%INSTALLDATE%$/ { getline; installed = $0 }
		/^%REASON%$/ { getline; reason = $0 }
		ENDFILE { if (reason == 0) print installed, name }
	' /var/lib/pacman/local/*/desc |
		sort -k1,1n -k2,2 | cut -d ' ' -f2- |
		fzf -m --no-sort --query="$*" --prompt 'pacr> ' --preview 'pacman -Qi {1}' |
		xargs -r -o sudo pacman -Rns --
}

paca() {
	pacman -Qq |
		fzf -m --query="$*" --prompt 'paca> ' --preview 'pacman -Qi {1}' |
		xargs -r -o sudo pacman -Rns --
}

# 仓库包显示构建时间；AUR 显示最后修改时间，完整元数据缓存一天。
_pkg_dates() {
	python3 - "$1" <<'PY'
from datetime import datetime
import gzip
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import time

rows = []
if sys.argv[1] == 'aur':
    cache = Path.home() / '.cache/paru/packages-meta-v1.json.gz'
    cache.parent.mkdir(parents=True, exist_ok=True)
    if not cache.exists() or time.time() - cache.stat().st_mtime > 86400:
        print('更新 AUR 包时间缓存…', file=sys.stderr)
        with tempfile.TemporaryDirectory(dir=cache.parent) as directory:
            tmp = Path(directory) / 'metadata.gz'
            subprocess.run(['curl', '-fLsS', '--connect-timeout', '10',
                            '--max-time', '120',
                            'https://aur.archlinux.org/packages-meta-v1.json.gz',
                            '-o', str(tmp)], check=True)
            # Validate before atomically replacing the previous cache.
            with gzip.open(tmp, 'rt') as data:
                packages = json.load(data)
            tmp.replace(cache)
    else:
        with gzip.open(cache, 'rt') as data:
            packages = json.load(data)
    rows = [(p['Name'], p['LastModified']) for p in packages]
else:
    repos = subprocess.check_output(['pacman-conf', '--repo-list'], text=True).splitlines()
    for repo in repos:
        with tarfile.open('/var/lib/pacman/sync/' + repo + '.db') as db:
            for member in db:
                if not member.name.endswith('/desc'):
                    continue
                text = db.extractfile(member).read().decode()
                fields = dict(part.split('\n', 1) for part in text.strip().split('\n\n'))
                rows.append((repo + '/' + fields['%NAME%'], int(fields['%BUILDDATE%'])))
for name, timestamp in sorted(rows):
    date = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M')
    print(f'{date:>16}  {name}')
PY
}

pacs() {
	_pkg_dates repo |
		fzf -m --nth=3 --query="$*" --prompt 'pacs> ' --preview 'pacman -Si {3}' |
		awk '{print $3}' | xargs -r -o sudo pacman -S --needed --
}

parus() {
	_pkg_dates aur |
		fzf -m --nth=3 --query="$*" --prompt 'parus> ' --preview 'paru -Sia {3}' |
		awk '{print $3}' | xargs -r -o paru -Sa --needed --
}

paco() {
	pacman -Qdtq |
		fzf -m --query="$*" --prompt 'paco> ' --preview 'pacman -Qi {1}' |
		xargs -r -o sudo pacman -Rns --
}

lfcd() {
	cd "$(command lf -print-last-dir "$@")" || return
}
alias lf=lfcd

ni() {
	if [[ -n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-} ]]; then
		echo "请先退出当前图形会话，再从 TTY 运行 ni。" >&2
		return 1
	fi
	export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-$UID}"
	install -d -m 700 "$XDG_RUNTIME_DIR" || return
	XDG_CURRENT_DESKTOP=niri XDG_SESSION_TYPE=wayland \
		GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx \
		dbus-run-session niri --session
}

HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend lithist

fastfetch
