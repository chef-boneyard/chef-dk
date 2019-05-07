context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
recipe_path = File.join(cookbook_dir, 'recipes', "#{context.new_file_basename}.rb")
spec_helper_path = File.join(cookbook_dir, 'spec', 'spec_helper.rb')
spec_dir = File.join(cookbook_dir, 'spec', 'unit', 'recipes')
spec_path = File.join(spec_dir, "#{context.new_file_basename}_spec.rb")
inspec_dir = File.join(cookbook_dir, 'test', 'integration', 'default')
inspec_path = File.join(inspec_dir, "#{context.new_file_basename}_test.rb")

if File.directory?(File.join(cookbook_dir, 'test', 'recipes'))
  Chef::Log.deprecation <<~EOH
    It appears that you have InSpec tests located at "test/recipes". This location can
    cause issues with Foodcritic and has been deprecated in favor of "test/integration/default".
    Please move your existing InSpec tests to the newly created "test/integration/default"
    directory, and update the 'inspec_tests' value in your kitchen.yml file(s) to
    point to "test/integration/default".
  EOH
end

# Chefspec
directory spec_dir do
  recursive true
end

cookbook_file spec_helper_path do
  action :create_if_missing
end

template spec_path do
  source 'recipe_spec.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# InSpec
directory inspec_dir do
  recursive true
end

template inspec_path do
  source 'inspec_default_test.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Recipe
template recipe_path do
  source 'recipe.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
end
