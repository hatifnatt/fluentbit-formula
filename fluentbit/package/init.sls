include:
  - .install

# Workaround for issue https://github.com/saltstack/salt/issues/65080
# require will fail if a requisite only include other .sls
# Adding dummy state as a workaround
fluentbit_package_init_dummy:
  test.show_notification:
    - text: "Workaround for salt issue #65080"
