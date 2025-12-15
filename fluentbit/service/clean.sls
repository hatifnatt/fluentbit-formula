{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{#- Stop and disable service #}
fluentbit_service_clean_dead:
  service.dead:
    - name: {{ flb.service.name }}

fluentbit_service_clean_disabled:
  service.disabled:
    - name: {{ flb.service.name }}
