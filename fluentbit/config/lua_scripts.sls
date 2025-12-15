{% set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}
{% from tplroot ~ '/macros.jinja' import build_source -%}


{%- if flb.install %}
include:
  - {{ tplroot }}.prepare
  - {{ tplroot }}.config.check
  - {{ tplroot }}.service

  {%- set lua_scripts_path = salt['file.join'](flb.conf_dir, flb.lua_scripts_dir) %}
  {#- Build lists with all files in current subdir, later managed files will be removed from this list #}
  {%- set lua_scripts_files = salt['file.find'](lua_scripts_path,type='fl',print='name') %}

fluentbit_config_lua_scripts_dir:
  file.directory:
    - name: "{{ lua_scripts_path }}"
    - user: {{ flb.root_user }}
    - group: {{ flb.root_group }}
    - dir_mode: 755
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

  {%- for lua_script_name, lua_script in flb.lua_scripts|dictsort %}
    {%- set ensure = lua_script.get('ensure', 'present') %}
    {%- set source = lua_script.get('source', '') %}
    {%- set lua_script_path_prefix = lua_script.get('path_prefix', flb.lookup.get('path_prefix', 'templates')) %}
    {#- Remove managed lua_script file name from all files list #}
    {%- if lua_script_name in lua_scripts_files %}
      {%- do lua_scripts_files.remove(lua_script_name) %}
    {%- endif %}
fluentbit_config_lua_scripts_<{{ lua_script_name }}>:
  file:
    - name: {{ lua_scripts_path ~ '/' ~ lua_script_name }}
    {%- if ensure == 'absent' %}
    - absent
    {%- elif ensure == 'present' %}
    - managed
    - source: {{ build_source(source, path_prefix=lua_script_path_prefix,
                              default_source='default/generic.lua.jinja') }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        script: {{ lua_script.get('script', {})|tojson }}
    - require:
      - file: fluentbit_config_lua_scripts_dir
    {%- endif %}
    - onchanges_in:
      - cmd: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
  {%- endfor %}

  {#- Remove all unmanaged lua_scripts if enabled in pillars #}
  {% if flb.lua_scripts_unmanaged_purge -%}
    {%- for snippet in lua_scripts_files %}
fluentbit_config_lua_scripts_unmanaged_snippet_<{{ snippet }}>_purge:
  file.absent:
    - name: {{ lua_scripts_path ~ '/' ~ snippet }}
    - onchanges_in:
      - sls: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
    {%- endfor %}
  {%- endif %}

{#- fluentbit is not selected for installation #}
{%- else %}
fluentbit_config_lua_scripts_install_notice:
  test.show_notification:
    - name: fluentbit_config_install_notice
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install Fluent Bit
        you need to set it to 'true'.

{%- endif %}
