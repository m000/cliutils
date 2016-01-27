### generic aliases ##########################################################
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

{% if hostname == "dastardly" -%}
### host-specific aliases for dastardly ######################################
alias pinplay-start="VBoxManage startvm 'Pin Play' --type headless"
alias pinplay-stop="VBoxManage controlvm 'Pin Play' acpipowerbutton"
alias tagit="open -a 'The Tagger'"
{% endif %}

{% if os == "osx" -%}
### osx-specific aliases #####################################################
alias ls='gls --color=tty'
alias sed=gsed
alias slt="open -a 'Sublime Text'"
alias sort=gsort
alias top='top -o cpu'
{%- elif os == "linux" -%}
### linux-specific aliases ###################################################
{%- endif %}

{% if hostid == "dastardly-osx" -%}
### host-specific aliases for dastardly-osx ##################################
alias pinplay-start="VBoxManage startvm 'Pin Play' --type headless"
alias pinplay-stop="VBoxManage controlvm 'Pin Play' acpipowerbutton"
alias tagit="open -a 'The Tagger'"
{% endif %}

{#-
### old/disabled aliases #####################################################
alias synergys='synergys -a 127.0.0.1 -f'
# vim:ft=sh
-#}
