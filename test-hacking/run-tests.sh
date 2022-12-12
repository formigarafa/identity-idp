#!/bin/bash
export COVERAGE=1
echo blueprints
bundle exec rspec --format json spec/blueprints >test-hacking/blueprints.json 2>&1
echo components
bundle exec rspec --format json spec/components >test-hacking/components.json 2>&1
echo config
bundle exec rspec --format json spec/config >test-hacking/config.json 2>&1
echo controllers
bundle exec rspec --format json spec/controllers >test-hacking/controllers.json 2>&1
echo decorators
bundle exec rspec --format json spec/decorators >test-hacking/decorators.json 2>&1
echo fixtures
bundle exec rspec --format json spec/fixtures >test-hacking/fixtures.json 2>&1
echo forms
bundle exec rspec --format json spec/forms >test-hacking/forms.json 2>&1
echo helpers
bundle exec rspec --format json spec/helpers >test-hacking/helpers.json 2>&1
echo rb
bundle exec rspec --format json spec/rb >test-hacking/rb.json 2>&1
echo javascripts
bundle exec rspec --format json spec/javascripts >test-hacking/javascripts.json 2>&1
echo jobs
bundle exec rspec --format json spec/jobs >test-hacking/jobs.json 2>&1
echo lib
bundle exec rspec --format json spec/lib >test-hacking/lib.json 2>&1
echo mailers
bundle exec rspec --format json spec/mailers >test-hacking/mailers.json 2>&1
echo models
bundle exec rspec --format json spec/models >test-hacking/models.json 2>&1
echo policies
bundle exec rspec --format json spec/policies >test-hacking/policies.json 2>&1
echo presenters
bundle exec rspec --format json spec/presenters >test-hacking/presenters.json 2>&1
echo requests
bundle exec rspec --format json spec/requests >test-hacking/requests.json 2>&1
echo routing
bundle exec rspec --format json spec/routing >test-hacking/routing.json 2>&1
echo scripts
bundle exec rspec --format json spec/scripts >test-hacking/scripts.json 2>&1
echo services
bundle exec rspec --format json spec/services >test-hacking/services.json 2>&1
echo views
bundle exec rspec --format json spec/views >test-hacking/views.json 2>&1
echo features
bundle exec rspec --format json spec/features >test-hacking/features.json 2>&1
