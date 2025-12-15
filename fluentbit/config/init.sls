{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}
{%- from tplroot ~ '/macros.jinja' import build_source %}


{%- if flb.install %}
  {#- Manage Fluent Bit configuration #}
include:
  - {{ tplroot }}.prepare
  {%- if flb.lua_scripts_dir and flb.lua_scripts %}
  - {{ tplroot }}.config.lua_scripts
  {%- endif %}
  - {{ tplroot }}.config.check
  - {{ tplroot }}.service

  {%- set main_config_path_prefix = flb.main_config.get('path_prefix',
                                                                        flb.lookup.get('path_prefix', 'templates')) %}
  {#- Try to guess main config default source (template) based on file extension #}
  {%- if flb.main_config.name.endswith('.conf') %}
    {%- set main_config_default_source = 'default/generic.conf.jinja' %}
  {%- elif flb.main_config.name.endswith('.yaml') or flb.main_config.name.endswith('.yml') %}
    {%- set main_config_default_source = 'default/generic.yaml.jinja' %}
  {%- endif %}

fluentbit_config_main:
  file.managed:
    - name: "{{ flb.conf_dir ~ '/' ~ flb.main_config.name }}"
    - source: {{ build_source(flb.main_config.source, path_prefix=main_config_path_prefix,
                              default_source=main_config_default_source) }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ flb.main_config.get('config', {})|tojson }}
    - require:
      - sls: {{ tplroot }}.prepare
    - onchanges_in:
      - cmd: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}

  {% for config_subdir, cdata in flb.configs|dictsort -%}
    {%- set configs_path = flb.conf_dir ~ '/' ~ config_subdir %}
    {#- Build lists with all files in current subdir, later managed files will be removed from this list #}
    {%- set config_files = salt['file.find'](configs_path,type='fl',print='name') %}
    {%- if cdata %}
fluentbit_config_subdir_<{{ config_subdir }}>:
  file.directory:
    - name: "{{ configs_path }}"
    - makedirs: true
    - require:
      - sls: {{ tplroot }}.prepare

      {%- for name, config in cdata|dictsort %}
        {#- Remove managed config file name from all files list #}
        {%- if name in config_files %}
          {%- do config_files.remove(name) %}
        {%- endif %}
        {%- if config %}
          {%- set ensure = config.get('ensure', 'present') %}
          {%- set source = config.get('source', '') %}
          {%- set config_path_prefix = config.get('path_prefix', flb.lookup.get('path_prefix', 'templates')) %}
          {#- Try to guess config default source (template) based on file extension #}
            {%- if name.endswith('.conf') %}
              {%- set config_default_source = 'default/generic.conf.jinja' %}
            {%- elif name.endswith('.yaml') or name.endswith('.yml') %}
              {%- set config_default_source = 'default/generic.yaml.jinja' %}
            {%- endif %}

fluentbit_config_<{{ config_subdir ~ '/' ~ name }}>:
  file:
    - name: "{{ configs_path ~ '/' ~ name }}"
            {%- if ensure == 'absent' %}
    - absent
    - onchanges_in:
      - cmd: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
            {%- elif ensure == 'present' %}
    - managed
    - source: {{ build_source(source, path_prefix=config_path_prefix,
                              default_source=config_default_source) }}
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        config: {{ config.get('config', {})|tojson }}
    - require:
      - file: fluentbit_config_subdir_<{{ config_subdir }}>
    - onchanges_in:
      - cmd: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
            {%- endif %}

          {#- Remove all unmanaged config files if enabled in pillars
              `loop.last` - render purge states only once after all
              valid files are removed from `config_files` list #}
          {%- if flb.configs_unmanaged_purge and loop.last %}
            {%- for config in config_files %}
fluentbit_config_unmanaged_<{{ config_subdir ~'/'~ config }}>_purge:
  file.absent:
    - name: "{{ configs_path ~ '/' ~ config }}"
    - onchanges_in:
      - cmd: fluentbit_config_check
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
            {%- endfor %}
          {%- endif %}

        {%- endif %}
      {%- endfor %}
    {%- endif %}
  {%- endfor %}

{#- Fluent Bit is not selected for installation #}
{%- else %}
fluentbit_config_install_notice:
  test.show_notification:
    - name: fluentbit_config_install_notice
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install Fluent Bit
        you need to set it to 'true'.

{%- endif %}
