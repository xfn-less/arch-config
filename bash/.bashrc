export GOPATH="$HOME/.local/share/go"
case ":$PATH:" in
	*":$HOME/.local/bin:"*) ;;
	*) PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
	*":$GOPATH/bin:"*) ;;
	*) PATH="$GOPATH/bin:$PATH" ;;
esac
export PATH

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

# Tab 多选，Enter 执行；Esc 取消。装/删仍确认；查询在 fzf 里打。已装标 *
pacs() {
	pacman -Sl core extra archlinuxcn |
		awk '{
			r = $1
			if (r == "core") r = "co"
			else if (r == "extra") r = "ex"
			else if (r == "archlinuxcn") r = "cn"
			mark = ($NF == "[installed]") ? "*" : " "
			printf "%-3s %s %s\n", r, $2, mark
		}' |
		fzf -m --preview 'pacman -Si {2}' |
		awk '{print $2}' |
		xargs -r -o sudo pacman -S --needed --
}

parus() {
	{
		paru -Sl
		paru -Sla
	} |
		awk '{
			r = $1
			if (r == "core") r = "co"
			else if (r == "extra") r = "ex"
			else if (r == "archlinuxcn") r = "cn"
			else if (r == "multilib") r = "ml"
			mark = ($NF == "[installed]") ? "*" : " "
			printf "%-3s %s %s\n", r, $2, mark
		}' |
		fzf -m --preview 'paru -Si {2}' |
		awk '{print $2}' |
		xargs -r -o paru -S --needed --
}

alias pacr='pacman -Qqe | fzf -m --preview "pacman -Qi {1}" | xargs -r -o sudo pacman -Rns --'
alias paca='pacman -Qq | fzf -m --preview "pacman -Qi {1}" | xargs -r -o sudo pacman -Rns --'
alias paco='sudo pacman -Rns $(pacman -Qdtq)'

d() {
	local tmp cwd
	tmp=$(mktemp -t yazi-cwd.XXXXXX) || return
	# alacritty 无图协议；清 NIRI_SOCKET，让内置预览走 Chafa（带缩图缓存）
	(unset NIRI_SOCKET; command yazi "$@" --cwd-file="$tmp")
	if cwd=$(<"$tmp") && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd" || return
	fi
	rm -f -- "$tmp"
}

HISTSIZE=100000
HISTFILESIZE=200000
# erasedups: 写入时清掉历史里同命令；不要 ignorespace，行首空格也会记
HISTCONTROL=erasedups
shopt -s histappend lithist
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"

# OpenSSH agent (systemd --user ssh-agent.socket)
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"

fastfetch
