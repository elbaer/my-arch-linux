# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=30000
SAVEHIST=1000
setopt autocd
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/cbaer/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

export TERM="xterm-256color"
alias vi="vim"
export VISUAL=vim
export EDITOR=vim

COMPLETION_WAITING_DOTS="true"
HIST_TIMESTAMP="yyyy-mm-dd"

bindkey "[C" forward-word
bindkey "[D" backward-word

if [[ $DISPLAY ]]; then
    source $HOME/.zshrc-desktop
else
    export ZSH=$HOME/.oh-my-zsh
    ZSH_THEME="clean"
    source $ZSH/oh-my-zsh.sh
fi