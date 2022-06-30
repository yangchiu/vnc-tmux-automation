Feature: demo feature

  Scenario: run a simple test
    Given longhorn installed

    Then create volume
    Then attach volume

    Then ssh into node
    Then write random data
    Then exit ssh
    Then expect volume actual size

    Then stop node
    Then expect volume robustness unknown
