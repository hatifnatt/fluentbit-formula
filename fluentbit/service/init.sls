{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}
{%- from tplroot ~ '/macros.jinja' import build_source %}

{%- if flb.install %}
fluentbit_service_systemd_drop-in:
  file.managed:
    - name: "/etc/systemd/system/{{ flb.service.name }}.service.d/conf-type.conf"
    - makedirs: true
    - template: jinja
    - source: {{ build_source(flb.service.systemd_drop_in_template, path_prefix='templates', default_source='systemd/drop-in.conf.jinja') }}
    - context:
        flb: {{ flb | json() }}

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

  {#-
    order: last ensures config files are written before the service is (re)started.
    onlyif skips the restart on a fresh install (service not yet running); the first
    start is handled by fluentbit_service_running below, also at order: last.
  #}
  {%- if flb.service.status == 'running' %}
fluentbit_service_restart_on_exec_change:
  service.running:
    - name: {{ flb.service.name }}
    - onlyif: "systemctl is-active {{ flb.service.name }}"
    - order: last
    - watch:
      - file: fluentbit_service_systemd_drop-in
  {%- endif %}

  {#- Manage on boot service state in dedicated state to ensure watch trigger properly in service.running state #}
fluentbit_service_{{ flb.service.on_boot_state }}:
  service.{{ flb.service.on_boot_state }}:
    - name: {{ flb.service.name }}

fluentbit_service_{{ flb.service.status }}:
  service:
    - name: {{ flb.service.name }}
    - {{ flb.service.status }}
  {#- reload is not implemented in fluent-bit systemd service file ... yet  #}
  {%- if flb.service.status == 'running' and flb.service.reload %}
    - reload: {{ flb.service.reload }}
  {%- endif %}
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
