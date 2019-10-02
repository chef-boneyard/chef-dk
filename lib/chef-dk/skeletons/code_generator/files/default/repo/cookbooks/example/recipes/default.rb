# This is a Chef Infra Client recipe file. It can be used to specify resources
# which will apply configuration to a server.

log "Welcome to Chef Infra Client, #{node['example']['name']}!" do
  level :info
end

# For more information, see the documentation: https://docs.chef.io/recipes.html
