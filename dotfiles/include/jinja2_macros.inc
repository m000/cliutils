{#
	Creates an argument list from the the specified dict d.
	Order of arguments is not guarantted!
#}
{% macro args_from_dict(d, kpref='-', kvsep=' ') %}
{% for k in d %}{{ kpref }}{{ k }} {{ d[k] }}{{ ' ' if not loop.last }}{% endfor %}
{% endmacro %}

{#
	Runs a command cmd with arguments specified in d.
	Only use this if arguments order does not matter!
#}
{% macro cmd_from_dict(cmd, d, kpref='-', kvsep=' ', require_args=True) %}
{% if d %}
{{ cmd }} {{ args_from_dict(d, kpref, kvsep) }}
{% elif not require_args %}
{{ cmd }}
{% else %}
# {{ '%-40s'|format(cmd) }}# no arguments - command skipped
{% endif %}
{% endmacro %}

{#
	Dumps a list of k, v pairs as environment variable definitions.
	We use a list of pairs rather than a dict to preserve order.
#}
{% macro env_from_list(l, export=True) %}
{% for t in l %}
{{ "export " if export }}{{ t[0] }}={{ t[1] }}
{% endfor %}
{% endmacro %}

