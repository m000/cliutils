{{ "Influential environment variables" | hr }}
### path
{% if path.homebrew is defined and path.homebrew|sh_expand|is_dir -%}
export HOMEBREW_PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/share/npm/bin
{%- endif %}
export HOMEBIN_PATH="$HOME"/bin:"$HOME"/git/cliutils/bin:"$HOME"/.cabal/bin
export PATH=$HOMEBREW_PATH:$PATH:$HOMEBIN_PATH:/opt/X11/bin:/usr/texbin
#export SSL_CERT_FILE=/opt/homebrew/opt/curl-ca-bundle/share/ca-bundle.crt
#export SVN_EDITOR=/opt/homebrew/bin/vim
#export EDITOR=/opt/homebrew/bin/vim
#export RSTUDIO_WHICH_R=/opt/homebrew/bin/R

#export JAVA_HOME="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
export PYTHONPATH=/opt/homebrew/lib/python${PYTHONPATH:+:$PYTHONPATH}
export PATH="$HOME/.cabal/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"


{%- if os == "osx" %}
export SSL_CERT_FILE=/opt/homebrew/opt/curl-ca-bundle/share/ca-bundle.crt
{% endif %}

