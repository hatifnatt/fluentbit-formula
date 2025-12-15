{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}
include:
{%- if flb.use_upstream in ('repo', 'package') %}
  - .package.install
{%- endif %}
