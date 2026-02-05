{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{%- if flb.install %}
fluentbit_service_systemd_drop-in:
  file.managed:
    - name: "/etc/systemd/system/{{ flb.service.name }}.service.d/conf-type.conf"
    - makedirs: true
    - contents: |
        [Service]
        ExecStart=
        ExecStart={{ flb.bin }} -c {{ flb.main_config_path }}{% if flb.service.args %} {{ flb.service.args|join(' ') }}{% endif %}

fluentbit_service_reload_systemd:
  module.wait:
  # Workaround for deprecated `module.run` syntax, subject to change in Salt 3005
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}
    - watch:
      - file: fluentbit_service_systemd_drop-in

  {#- Manage on boot service state in dedicated state to ensure watch trigger properly in service.running state #}
fluentbit_service_{{ flb.service.on_boot_state }}:
  service.{{ flb.service.on_boot_state }}:
    - name: {{ flb.service.name }}

fluentbit_service_{{ flb.service.status }}:
  service:
    - name: {{ flb.service.name }}
    - {{ flb.service.status }}
  {#- reload is not implemented in fluent-bit systemd service file ... yet  #}
  {#-
  {%- if flb.service.status == 'running' %}
    - reload: {{ flb.service.reload }}
  {%- endif %}
  #}
    - require:
        - service: fluentbit_service_{{ flb.service.on_boot_state }}
    - order: last

{#- Fluent Bit is not selected for installation #}
{%- else %}
fluentbit_service_notice:
  test.show_notification:
    - name: fluentbit_service_notice
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install Fluent Bit
        you need to set it to 'true'.

{%- endif %}
