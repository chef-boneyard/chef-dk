# ChefDK 1.1 Release notes

## New Inspec Test Location
To address bugs and confusion with the previous `test/recipes` location, all newly generated
cookbooks and recipes will place their Inspec tests in `test/smoke/default`. This
placement creates the association of the `smoke` Workflow phase and the `default` Kitchen suite
where the tests are run.
