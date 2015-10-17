
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)

# cookbook root dir
directory cookbook_dir

# metadata.rb
template "#{cookbook_dir}/metadata.rb" do
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# README
template "#{cookbook_dir}/README.md" do
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# chefignore
cookbook_file "#{cookbook_dir}/chefignore"

# Rakefile
cookbook_file "#{cookbook_dir}/Rakefile"

# Policyfile
template "#{cookbook_dir}/Policyfile.rb" do
  source "Policyfile.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

###
# Berks is no longer the default, uncomment this to enable it.
#
# # Berks
# cookbook_file "#{cookbook_dir}/Berksfile" do
#   action :create_if_missing
# end

# TK & Serverspec
template "#{cookbook_dir}/.kitchen.yml" do
  ## Uncomment this and delete the following `source` line to generate
  ## non-Policyfile kitchen.yml files (do this if you're using berks):
  # source 'kitchen.yml.erb'
  source 'kitchen_policyfile.yml.erb'
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Directory to collect CI reports
directory "#{cookbook_dir}/test/reports" do
  recursive true
end
file "#{cookbook_dir}/test/reports/.keep"

directory "#{cookbook_dir}/test/integration/default/serverspec" do
  recursive true
end

directory "#{cookbook_dir}/test/integration/helpers/serverspec" do
  recursive true
end

cookbook_file "#{cookbook_dir}/test/integration/helpers/serverspec/spec_helper.rb" do
  source 'serverspec_spec_helper.rb'
  action :create_if_missing
end

template "#{cookbook_dir}/test/integration/default/serverspec/default_spec.rb" do
  source 'serverspec_default_spec.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Chefspec
directory "#{cookbook_dir}/spec/unit/recipes" do
  recursive true
end

cookbook_file "#{cookbook_dir}/spec/spec_helper.rb" do
  # Change this to "spec_helper.rb" to get the berkshelf version
  source "spec_helper_policyfile.rb"
  action :create_if_missing
end

template "#{cookbook_dir}/spec/unit/recipes/default_spec.rb" do
  source "recipe_spec.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Recipes

directory "#{cookbook_dir}/recipes"

template "#{cookbook_dir}/recipes/default.rb" do
  source "recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# git
if context.have_git
  if !context.skip_git_init

    execute("initialize-git") do
      command("git init .")
      cwd cookbook_dir
    end
  end

  cookbook_file "#{cookbook_dir}/.gitignore" do
    source "gitignore"
  end
end
