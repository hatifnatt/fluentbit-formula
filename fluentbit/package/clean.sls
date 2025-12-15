{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import fluentbit as flb %}

include:
  - {{ tplroot }}.service.clean
  - {{ tplroot }}.repo.clean

fluentbit_package_clean:
  pkg.removed:
    - pkgs:
    {%- for pkg in flb.package.pkgs %}
      - {{ pkg }}
    {%- endfor %}
    - require_in:
      - sls: {{ tplroot }}.repo.clean
