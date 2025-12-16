{% set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

fluentbit_prepare_conf_dir:
  file.directory:
    - name: "{{ flb.conf_dir }}"
    - user: {{ flb.root_user }}
    - group: {{ flb.root_group }}
    - dir_mode: 755
    - makedirs: true

fluentbit_prepare_backup_default_config:
  file.copy:
    - name: "{{ flb.conf_dir ~ '/' ~ flb.main_config.name ~ '.example' }}"
    - source: "{{ flb.conf_dir ~ '/' ~ flb.main_config.name }}"
    - preserve: true
    - creates: "{{ flb.conf_dir ~ '/' ~ flb.main_config.name ~ '.example' }}"
    - onlyif: test -f "{{ flb.conf_dir ~ '/' ~ flb.main_config.name }}"
