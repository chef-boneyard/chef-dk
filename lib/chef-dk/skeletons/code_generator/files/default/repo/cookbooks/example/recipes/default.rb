# This is a Chef recipe file. It can be used to specify resources which will
# apply configuration to a server.

log "Welcome to Chef, #{node["example_name"]}!" do
  level :info
end

# For more information, see the documentation: http://docs.getchef.com/essentials_cookbook_recipes.html
