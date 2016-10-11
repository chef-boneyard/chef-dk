
context = ChefDK::Generator.context
delivery_project_dir = context.delivery_project_dir
pipeline = context.pipeline
dot_delivery_dir = File.join(delivery_project_dir, ".delivery")

generator_desc("Ensuring delivery configuration")

directory dot_delivery_dir

cookbook_file File.join(dot_delivery_dir, "config.json") do
  source "delivery-config.json"
end

# Adding a new prototype file for delivery-cli local commands
cookbook_file File.join(dot_delivery_dir, "project.toml") do
  source "delivery-project.toml"
end

generator_desc("Ensuring correct delivery build cookbook content")

build_cookbook_dir = File.join(dot_delivery_dir, "build_cookbook")

# cookbook root dir
directory build_cookbook_dir

# metadata.rb
template "#{build_cookbook_dir}/metadata.rb" do
  source "build_cookbook/metadata.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# README
cookbook_file "#{build_cookbook_dir}/README.md" do
  source "build_cookbook/README.md"
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
  source "build_cookbook/Berksfile.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

# Recipes
directory "#{build_cookbook_dir}/recipes"

%w(default deploy functional lint provision publish quality security smoke syntax unit).each do |phase|
  template "#{build_cookbook_dir}/recipes/#{phase}.rb" do
    source 'build_cookbook/recipe.rb.erb'
    helpers(ChefDK::Generator::TemplateHelper)
    variables phase: phase
    action :create_if_missing
  end
end

# Test Kitchen build node
cookbook_file "#{build_cookbook_dir}/.kitchen.yml" do
  source "build_cookbook/.kitchen.yml"
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
  source "build_cookbook/test-fixture-recipe.rb"
end

# Construct git history as if we did all the work in a feature branch which we
# merged into master at the end, which looks like this:
#
# ```
# git log --graph --oneline
# *   5fec5bd Merge branch 'add-delivery-configuration'
# |\
# | * 967bb9f Add generated delivery build cookbook
# | * 1558e0a Add generated delivery configuration
# |/
# * db22790 Add generated cookbook content
# ```
#
if context.have_git && context.delivery_project_git_initialized && !context.skip_git_init

  generator_desc("Adding delivery configuration to feature branch")

  execute("git-create-feature-branch") do
    command("git checkout -t -b add-delivery-configuration")
    cwd delivery_project_dir
  end

  execute("git-add-delivery-config-json") do
    command("git add .delivery/config.json")
    cwd delivery_project_dir

    only_if "git status --porcelain |grep \".\""
  end

  # Adding the new prototype file to the feature branch
  # so it gets checked in with the delivery config commit
  execute("git-add-delivery-project-toml") do
    command("git add .delivery/project.toml")
    cwd delivery_project_dir

    only_if "git status --porcelain |grep \".\""
  end

  execute("git-commit-delivery-config") do
    command("git commit -m \"Add generated delivery configuration\"")
    cwd delivery_project_dir

    only_if "git status --porcelain |grep \".\""
  end

  generator_desc("Adding build cookbook to feature branch")

  execute("git-add-delivery-build-cookbook-files") do
    command("git add .delivery")
    cwd delivery_project_dir

    only_if "git status --porcelain |grep \".\""
  end

  execute("git-commit-delivery-build-cookbook") do
    command("git commit -m \"Add generated delivery build cookbook\"")
    cwd delivery_project_dir

    only_if "git status --porcelain |grep \".\""
  end

  execute("git-return-to-#{pipeline}-branch") do
    command("git checkout #{pipeline}")
    cwd delivery_project_dir
  end

  generator_desc("Merging delivery content feature branch to master")

  execute("git-merge-delivery-config-branch") do
    command("git merge --no-ff add-delivery-configuration")
    cwd delivery_project_dir
  end

  execute("git-remove-delivery-config-branch") do
    command("git branch -D add-delivery-configuration")
    cwd delivery_project_dir
  end
end
