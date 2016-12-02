
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
recipe_path = File.join(cookbook_dir, "recipes", "#{context.new_file_basename}.rb")
spec_helper_path = File.join(cookbook_dir, "spec", "spec_helper.rb")
spec_dir = File.join(cookbook_dir, "spec", "unit", "recipes")
spec_path = File.join(spec_dir, "#{context.new_file_basename}_spec.rb")
inspec_dir = File.join(cookbook_dir, "test", "smoke", "default")
inspec_path = File.join(inspec_dir, "#{context.new_file_basename}.rb")

# Chefspec
directory spec_dir do
  recursive true
end

cookbook_file spec_helper_path do
  action :create_if_missing
end

template spec_path do
  source "recipe_spec.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Inspec
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
  source "recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end
