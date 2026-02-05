{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import fluentbit as flb %}
{%- from tplroot ~ '/macros.jinja' import build_source %}

{%- if flb.install %}
  {%- if 'logrotate' in flb and flb.logrotate.get('enable', True) %}
include:
  - {{ tplroot }}.prepare

fluentbit_logrotate_install_package:
  pkg.installed:
    - pkgs: {{ flb.logrotate.package.pkgs|tojson }}
    - require_in:
      - file: fluentbit_logrotate_config

fluentbit_logrotate_config:
  file.managed:
    - name: /etc/logrotate.d/fluent-bit
    - source: {{ build_source('etc/logrotate.d/fluent-bit') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ flb.logrotate.get('config', {})|tojson }}
        logs_dir: {{ flb.logs_dir }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: fluentbit_prepare_logs_dir

  {#- Logrotate configuration is not selected for installation #}
  {%- else %}
fluentbit_logrotate_not_enabled:
  test.show_notification:
    - name: fluentbit_logrotate_not_enabled
    - text: |
        Logrotate configuration is not selected for installation, current value
        for 'fluentbit:logrotate.enable: {{ flb.logrotate.enable|string|lower }},
        if you want to install logrotate and setup rotation for Fluent Bit logs
        you need to set it to 'true'.

  {%- endif %}

{#- Fluent Bit is not selected for installation #}
{%- else %}
fluentbit_logrotate_notice:
  test.show_notification:
    - name: fluentbit_logrotate_notice
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install Fluent Bit
        you need to set it to 'true'.

{%- endif %}
