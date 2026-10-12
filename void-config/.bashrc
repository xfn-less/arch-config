[[ $- == *i* ]] || return

PS1='\[\e[1m\]\A \W\$ \[\e[0m\]'

. /usr/share/bash-completion/bash_completion
eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS='--style minimal --layout reverse --info inline --exact'
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

xbs() {
	local pkgs
	pkgs=$(
		xbps-query -Rs . |
			fzf -m --query="$*" --prompt 'xbs> ' \
				--preview 'xbps-query -RS {2}' --preview-window right,50%,noborder |
			awk '{print $2}' |
			xargs -r -n1 xbps-uhelper getpkgname
	)
	[[ -n $pkgs ]] || return
	sudo xbps-install -y $pkgs
}

xbr() {
	local pkgs
	pkgs=$(
		xbps-query -m |
			xargs -r -n1 xbps-uhelper getpkgname |
			fzf -m --query="$*" --prompt 'xbr> ' \
				--preview 'xbps-query -S {1}' --preview-window right,50%,noborder
	)
	[[ -n $pkgs ]] || return
	sudo xbps-remove -Ry $pkgs
}

xba() {
	local pkgs
	pkgs=$(
		xbps-query -l | sed 's/^.. //' |
			fzf -m --query="$*" --prompt 'xba> ' \
				--preview 'xbps-query -S {1}' --preview-window right,50%,noborder |
			awk '{print $1}' |
			xargs -r -n1 xbps-uhelper getpkgname
	)
	[[ -n $pkgs ]] || return
	sudo xbps-remove -Ry $pkgs
}

xbo() {
	local pkgs
	pkgs=$(xbps-query -O) || return
	[[ -n $pkgs ]] || return
	pkgs=$(
		printf '%s\n' "$pkgs" |
			fzf -m --query="$*" --prompt 'xbo> ' \
				--preview 'xbps-remove -nR {1}' --preview-window right,50%,noborder |
			xargs -r -n1 xbps-uhelper getpkgname
	)
	[[ -n $pkgs ]] || return
	sudo xbps-remove -Ry $pkgs
}

xbf() {
	local pkg
	pkg=$(
		xbps-query -l |
			fzf --query="$*" --prompt 'xbf> ' \
				--preview 'xbps-query -f {2}' --preview-window right,50%,noborder |
			awk '{print $2}'
	)
	[[ -n $pkg ]] || return
	xbps-query -f "$(xbps-uhelper getpkgname "$pkg")"
}

xbu() { sudo xbps-install -Syu; }
xbc() { sudo xbps-remove -O; }

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
