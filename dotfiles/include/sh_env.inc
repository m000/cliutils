{{ "Influential environment variables" | hr }}
### path
{#-
    To build the PATH environment variable we create a list which we then join and print.
#}
{% with -%}
    {%- set path_env=['"$PATH"',] -%}

    {#- Add /sbin to path - contains ifconfig -#}
    {%- if os.type == "linux" -%}
        {%- do path_env.append('/sbin') -%}
    {%- endif -%}

    {#- Intel Pin -#}
    {%- if path.pin is dir -%}
        export PIN_HOME="{{path.pin}}"
        {%- do path_env.append('"$PIN_HOME"') -%}
    {%- endif -%}

    {#- Homebrew -#}
    {%- if path.homebrew is dir -%}
        export HOMEBREW_PATH="{{path.homebrew}}/bin":"{{path.homebrew}}/sbin":"{{path.homebrew}}/share/npm/bin"
        {%- do path_env.insert(0, '"$HOMEBREW_PATH"') -%}
    {%- endif -%}

    {#- Haskell package manager -#}
    {%- if "$HOME/.cabal/bin" is dir -%}
        {%- do path_env.insert(0, '"$HOME"/.cabal/bin') -%}
    {%- endif -%}

    {#- Home bin -#}
    {%- if "$HOME/bin" is dir -%}
        {%- do path_env.append('"$HOME"/bin') -%}
    {%- endif -%}

    {#- Cliutils -#}
    {%- if path.cliutils is dir -%}
        {%- do path_env.append('"%s"/bin' % (path.cliutils)) -%}
    {%- endif -%}

    {#- Output PATH #}
export PATH={{ path_env|join(':') }}
{%- endwith %}

### other stuff
{% if "vim" is installed -%}
export EDITOR=vim
export SVN_EDITOR=vim
{%- endif %}

{#
#export RSTUDIO_WHICH_R=/opt/homebrew/bin/R
#export JAVA_HOME="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
#export PYTHONPATH=/opt/homebrew/lib/python${PYTHONPATH:+:$PYTHONPATH}
#export PATH="$HOME/.cabal/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
# Virtualenv Wrapper
if [ -f /opt/homebrew/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME="$HOME"/Library/PyEnv
    source /opt/homebrew/bin/virtualenvwrapper.sh
fi
#}

{%- if os.type == "osx" %}
export SSL_CERT_FILE=/opt/homebrew/opt/curl-ca-bundle/share/ca-bundle.crt
#export PATH=/opt/X11/bin:/usr/texbin
{% endif %}

{#-
# vim:ft=sh
-#}
