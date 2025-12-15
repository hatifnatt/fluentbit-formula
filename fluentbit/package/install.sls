{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

{%- if flb.install %}
  {#- Install Fluent Bit from packages #}
  {%- if flb.use_upstream in ('repo', 'package') %}
include:
  - {{ tplroot }}.repo.install
  - {{ tplroot }}.service

    {#- Install packages required for further execution of 'package' installation method #}
    {%- if 'prereq_pkgs' in flb.package and flb.package.prereq_pkgs %}
fluentbit_package_install_prerequisites:
  pkg.installed:
    - pkgs: {{ flb.package.prereq_pkgs|tojson }}
    - require:
      - sls: {{ tplroot }}.repo.install
    - require_in:
      - pkg: fluentbit_package_install
    {%- endif %}

    {%- if 'pkgs_extra' in flb.package and flb.package.pkgs_extra %}
fluentbit_package_install_extra:
  pkg.installed:
    - pkgs: {{ flb.package.pkgs_extra|tojson }}
    - require:
      - sls: {{ tplroot }}.repo.install
    - require_in:
      - pkg: fluentbit_package_install
    {%- endif %}

fluentbit_package_install:
  pkg.installed:
    - pkgs:
    {%- for pkg in flb.package.pkgs %}
      - {{ pkg }}{% if 'version' in flb and flb.version and 'fluent-bit' in pkg %}: '{{ flb.version }}*'{% endif %}
    {%- endfor %}
    - hold: {{ flb.package.hold }}
    - update_holds: {{ flb.package.update_holds }}
    {%- if salt['grains.get']('os_family') == 'Debian' %}
    - install_recommends: {{ flb.package.install_recommends }}
    {%- endif %}
    - watch_in:
      - service: fluentbit_service_{{ flb.service.status }}
    - require:
      - sls: {{ tplroot }}.repo.install
    - require_in:
      - sls: {{ tplroot }}.service

  {#- Another installation method is selected #}
  {%- else %}
fluentbit_package_install_method:
  test.show_notification:
    - name: fluentbit_package_install_method
    - text: |
        Another installation method is selected. If you want to use package
        installation method set 'fluentbit:use_upstream' to 'package' or 'repo'.
        Current value of fluentbit:use_upstream: '{{ flb.use_upstream }}'
  {%- endif %}

{#- Fluent Bit is not selected for installation #}
{%- else %}
fluentbit_package_install_notice:
  test.show_notification:
    - name: fluentbit_package_install
    - text: |
        Fluent Bit is not selected for installation, current value
        for 'fluentbit:install': {{ flb.install|string|lower }}, if you want to install Fluent Bit
        you need to set it to 'true'.

{%- endif %}
