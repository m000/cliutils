{{ "Influential environment variables" | hr }}
### path
{#-
    To build the PATH environment variable we create a list which we then join and print.
#}
{% with -%}
    {%- set path_env=['"$PATH"',] -%}
    {%- set exports=[] -%}

    {#- Add /sbin to path - contains ifconfig -#}
    {%- if os.type == "linux" -%}
        {%- do path_env.append('/sbin') -%}
    {%- endif -%}

    {#- Intel Pin -#}
    {%- if path.pin is dir -%}
        {%- do exports.append(('PIN_ROOT', '"{0}"'.format(path.pin))) -%}
        {%- do path_env.append('"$PIN_ROOT"') -%}
    {%- endif -%}

    {#- LLVM -#}
    {%- if path.llvm is dir -%}
        {%- do exports.append(('LLVM_ROOT', '"{0}"'.format(path.llvm))) -%}
        {%- do path_env.insert(0, '"$LLVM_ROOT/bin"') -%}
    {%- endif -%}

    {#- Homebrew -#}
    {%- if path.homebrew is dir -%}
        {%- do exports.append(('HOMEBREW_PATH', '"{0}/bin":"{0}/sbin":"{0}/share/npm/bin"'.format(path.homebrew))) -%}
        {%- do path_env.insert(0, '"$HOMEBREW_PATH"') -%}
    {%- endif -%}

    {#- Haskell package manager -#}
    {%- if "$HOME/.cabal/bin" is dir -%}
        {%- do path_env.insert(0, '"$HOME"/.cabal/bin') -%}
    {%- endif -%}

    {#- Home bin -#}
    {%- if "$HOME/bin" is dir -%}
        {%- do exports.append(('HOMEBREW_PATH', '"{0}/bin":"{0}/sbin":"{0}/share/npm/bin"'.format(path.llvm))) -%}
        {%- do path_env.append('"$HOME"/bin') -%}
    {%- endif -%}

    {#- Cliutils -#}
    {%- if path.cliutils is dir -%}
        {%- do path_env.append('"%s"/bin' % (path.cliutils)) -%}
    {%- endif -%}

    {#- Output exports and PATH #}
{%- for k, v in exports -%}
export {{k}}={{v}}
{% endfor -%}
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
# export SSH_KEY_PATH="~/.ssh/dsa_id"
# Virtualenv Wrapper
if [ -f /opt/homebrew/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME="$HOME"/Library/PyEnv
    source /opt/homebrew/bin/virtualenvwrapper.sh
fi
#}

### os specific settings
{% if os.type == "osx" -%}
{#- curl-ca-bundle has been deprecated #}
{% if (path.homebrew + 'opt/curl-ca-bundle/share/ca-bundle.crt') is file %}
export SSL_CERT_FILE={{(path.homebrew + 'opt/curl-ca-bundle/share/ca-bundle.crt')}}
{% endif %}
{% endif %}

### host specific settings
{% if hostname == 'debian64' -%}
ulimit -c unlimited
{% endif %}


{#-
# vim:ft=sh
-#}
