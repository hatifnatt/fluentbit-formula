{% set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{%- if flb.install %}

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

fluentbit_prepare_storage_dir:
  file.directory:
    - name: "{{ flb.storage_dir }}"
    - user: {{ flb.root_user }}
    - group: {{ flb.root_group }}
    - dir_mode: 755
    - makedirs: true

fluentbit_prepare_db_dir:
  file.directory:
    - name: "{{ flb.db_dir }}"
    - user: {{ flb.root_user }}
    - group: {{ flb.root_group }}
    - dir_mode: 755
    - makedirs: true

fluentbit_prepare_logs_dir:
  file.directory:
    - name: "{{ flb.logs_dir }}"
    - user: {{ flb.root_user }}
    - group: {{ flb.root_group }}
    - dir_mode: 755
    - makedirs: true

{%- else %}

fluentbit_prepare_install_notice:
  test.show_notification:
    - name: fluentbit_prepare_install_notice
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to create
        directories for Fluent Bit data, you need to set it to 'true'.

{%- endif %}
