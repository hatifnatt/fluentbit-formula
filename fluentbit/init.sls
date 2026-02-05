{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

include:
  - .install
  {%- if 'logrotate' in flb and flb.logrotate.get('enable', True) %}
  - .logrotate
  {%- endif %}
  - .config
