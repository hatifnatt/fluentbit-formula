fluentbit_logrotate_clean_config:
  file.absent:
    - name: /etc/logrotate.d/fluent-bit
