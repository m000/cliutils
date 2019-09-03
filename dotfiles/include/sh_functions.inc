{% if os.type == "osx" -%}
lock-console() {
	"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession" -suspend
}
{% endif %}

{#-
# vim:ft=sh
-#}
