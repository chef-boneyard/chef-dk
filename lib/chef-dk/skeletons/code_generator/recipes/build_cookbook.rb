
context = ChefDK::Generator.context
delivery_project_dir = context.delivery_project_dir
dot_delivery_dir = File.join(delivery_project_dir, ".delivery")

directory dot_delivery_dir

cookbook_file File.join(dot_delivery_dir, "config.json") do
  source "delivery-config.json"
end

build_cookbook_dir = File.join(dot_delivery_dir, "build-cookbook")

# cookbook root dir
directory build_cookbook_dir

# metadata.rb
template "#{build_cookbook_dir}/metadata.rb" do
  source "build-cookbook/metadata.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# README
cookbook_file "#{build_cookbook_dir}/README.md" do
  source "build-cookbook/README.md"
  action :create_if_missing
end

# LICENSE
template "#{build_cookbook_dir}/LICENSE" do
  source "LICENSE.#{context.license}.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# chefignore
cookbook_file "#{build_cookbook_dir}/chefignore"

# Berksfile
template "#{build_cookbook_dir}/Berksfile" do
  source "build-cookbook/Berksfile.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Recipes
directory "#{build_cookbook_dir}/recipes"

%w(default deploy functional lint provision publish quality security smoke syntax unit).each do |phase|
  template "#{build_cookbook_dir}/recipes/#{phase}.rb" do
    source 'build-cookbook/recipe.rb.erb'
    helpers(ChefDK::Generator::TemplateHelper)
    variables phase: phase
    action :create_if_missing
  end
end

# Test Kitchen build node
cookbook_file "#{build_cookbook_dir}/.kitchen.yml" do
  source "build-cookbook/.kitchen.yml"
end

directory "#{build_cookbook_dir}/data_bags/keys" do
  recursive true
end

file "#{build_cookbook_dir}/data_bags/keys/delivery_builder_keys.json" do
  content '{"id": "delivery_builder_keys"}'
end

directory "#{build_cookbook_dir}/secrets"

file "#{build_cookbook_dir}/secrets/fakey-mcfakerton"

directory "#{build_cookbook_dir}/test/fixtures/cookbooks/test/recipes" do
  recursive true
end

file "#{build_cookbook_dir}/test/fixtures/cookbooks/test/metadata.rb" do
  content %(name 'test'
version '0.1.0')
end

cookbook_file "#{build_cookbook_dir}/test/fixtures/cookbooks/test/recipes/default.rb" do
  source "build-cookbook/test-fixture-recipe.rb"
end

