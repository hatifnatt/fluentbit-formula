{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{#- Stop and disable service #}
fluentbit_service_clean_dead:
  service.dead:
    - name: {{ flb.service.name }}

fluentbit_service_clean_disabled:
  service.disabled:
    - name: {{ flb.service.name }}

fluentbit_service_clean_systemd_drop-in:
  file.absent:
    - name: "/etc/systemd/system/{{ flb.service.name }}.service.d/conf-type.conf"

fluentbit_service_clean_reload_systemd:
  module.wait:
  # Workaround for deprecated `module.run` syntax, subject to change in Salt 3005
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}
    - watch:
      - file: fluentbit_service_clean_systemd_drop-in
