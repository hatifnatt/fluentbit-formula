{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{#  Check config before restarting service, do not restart if check failed
    NB! Dry Run can miss errors in configuration files! #}
fluentbit_config_check:
  cmd.run:
    - name: >-
        {{ flb.bin }} --dry-run
        {{ '--quiet' if flb.get('quiet_config_check', true) and '--quiet' not in flb.service.args and '-q' not in flb.service.args }}
        -c {{ flb.main_config_path }}
        {%- if flb.service.args %} {{ flb.service.args|join(' ') }}{% endif %}
    - require_in:
      - service: fluentbit_service_{{ flb.service.status }}
