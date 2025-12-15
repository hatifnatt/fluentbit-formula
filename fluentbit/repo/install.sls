{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}
{%- from tplroot ~ '/macros.jinja' import format_kwargs %}

{%- if flb.install %}
  {#- If fluentbit:use_official_repo is true official repo will be configured #}
  {%- if flb.use_official_repo %}

    {#- Install required packages if defined #}
    {%- if flb.repo.prerequisites %}
fluentbit_repo_install_prerequisites:
  pkg.installed:
    - pkgs: {{ flb.repo.prerequisites|tojson }}
    {%- endif %}

    {#- Install keyring / gpg key if provided #}
    {%- if 'keyring' in flb.repo and flb.repo.keyring %}
      {#- If only one keyring configuration is present - convert it to list #}
      {%- if flb.repo.keyring is mapping %}
        {%- set keyrings = [flb.repo.keyring] %}
      {%- else %}
        {%- set keyrings = flb.repo.keyring %}
      {%- endif %}
      {%- for keyring in keyrings %}
        {#- Install keyring if provided, for Debian based systems only #}
fluentbit_repo_install_keyring_{{ loop.index0 }}:
  file.managed:
    - name: {{ keyring.get('dst', '') }}
    - source: {{ keyring.get('src', '') }}
    - skip_verify: {{ keyring.get('skip_verify', false) }}
      {%- endfor %}
    {%- endif %}

    {#- If only one repo configuration is present - convert it to list #}
    {%- if flb.repo.config is mapping %}
      {%- set configs = [flb.repo.config] %}
    {%- else %}
      {%- set configs = flb.repo.config %}
    {%- endif %}
    {%- for config in configs %}
fluentbit_repo_install_{{ loop.index0 }}:
  pkgrepo.managed:
    {{- format_kwargs(config) }}
      {%- if 'keyring' in flb.repo and flb.repo.keyring %}
    - require:
      - file: fluentbit_repo_install_keyring_*
      {%- endif %}
    {%- endfor %}

  {#- Official repo configuration is not requested #}
  {%- else %}
fluentbit_repo_install_method:
  test.show_notification:
    - name: fluentbit_repo_install_method
    - text: |
        Official repo configuration is not requested.
        If you want to configure repository set 'fluentbit:use_official_repo' to true.
        Current value of fluentbit:use_official_repo: '{{ flb.use_official_repo }}'
  {%- endif %}

{#- fluentbit is not selected for installation #}
{%- else %}
fluentbit_repo_install_notice:
  test.show_notification:
    - name: fluentbit_repo_install
    - text: |
        fluentbit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install fluentbit
        you need to set it to 'true'.

{%- endif %}
