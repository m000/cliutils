{{ "Generic aliases" | hr }}
### job control
alias STOP='killall -STOP'
alias CONT='killall -CONT'
### text manipulation
alias lnmerge="tr '\n' ' '"
alias titlecase="sed -r 's/((^|[[:blank:]])[[:alpha:]])([[:alpha:]]*)/\U\1\L\3/g'"
alias sigmafix="sed -r 's/σ([^[:alpha:]]|$)/ς\1'/g"
### program-specific shorthands
alias gvimt='gvim --remote-tab'
alias nyancat='telnet nyancat.dakko.us'
alias svnup='svn up --ignore-externals'
alias ts='date +"%Y-%m-%d %H:%M:%S"'
alias vi=vim
{% if 'subl' is installed -%}
{# on mac: sudo ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/ #}
alias slt="subl -a"
{% endif %}

{{ "OS-specific aliases for %s" | format(os.type) | hr }}
{% if os.type == "osx" -%}
alias ldd='otool -L'
alias ls='ls --color=tty'
alias m='make -j $(sysctl -n hw.ncpu)'
alias top='top -o cpu'
{%- elif os.type == "linux" %}
{%- if 'xdg-open' is installed -%}
alias open="xdg-open"
{% endif -%}
alias m='make -j $(nproc)'
{%- elif os.type == "bsd" %}
alias make=gmake
{%- endif %}

{{ "Host-specific aliases for %s" | format(hostid) | hr }}
{% if hostid == "The-Shrine-osx" -%}
alias tagit="open -a 'The Tagger'"
alias xpra="/Applications/Xpra.app/Contents/MacOS/Xpra"
{%- else -%}
# nothing yet!
{%- endif %}

{#
### old/disabled aliases #####################################################
alias synergys='synergys -a 127.0.0.1 -f'
# vim:ft=sh
-#}

