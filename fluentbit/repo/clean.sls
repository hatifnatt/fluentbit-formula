{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{#- Remove any configured repo form the system #}
{#- If only one repo configuration is present - convert it to list #}
{%- if flb.repo.config is mapping %}
  {%- set configs = [flb.repo.config] %}
{%- else %}
  {%- set configs = flb.repo.config %}
{%- endif %}
{%- for config in configs %}
fluentbit_repo_clean_{{ loop.index0 }}:
  {%- if grains.os_family != 'Debian' %}
  pkgrepo.absent:
    - name: {{ config.name | yaml_dquote }}
  {%- else %}
  {#- Due bug in pkgrepo.absent we need to manually remove repository '.list' files
      See https://github.com/saltstack/salt/issues/61602 #}
  file.absent:
    - name: {{ config.file }}
  {%- endif %}
{%- endfor %}

{#- Remove keyring files if present #}
{%- if 'keyring' in flb.repo and flb.repo.keyring %}
  {#- If only one keyring configuration is present - convert it to list #}
  {%- if flb.repo.keyring is mapping %}
    {%- set keyrings = [flb.repo.keyring] %}
  {%- else %}
    {%- set keyrings = flb.repo.keyring %}
  {%- endif %}
  {%- for keyring in keyrings %}
fluentbit_repo_clean_keyring_{{ loop.index0 }}:
  file.absent:
    - name: {{ keyring.get('dst', '') }}
  {%- endfor %}
{%- endif %}
