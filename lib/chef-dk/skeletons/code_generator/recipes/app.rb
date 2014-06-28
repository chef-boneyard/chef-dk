

context = ChefDK::Generator.context
app_dir = File.join(context.app_root, context.app_name)
cookbooks_dir = context.cookbook_root
cookbook_dir = File.join(cookbooks_dir, context.cookbook_name)

cookbook_dir = File.join(cookbooks_dir, context.app_name)

# app root dir
directory app_dir

# Top level files

# TK
template "#{app_dir}/.kitchen.yml" do
  source 'kitchen.yml.erb'
  helpers(ChefDK::Generator::TemplateHelper)
end

# README
template "#{app_dir}/README.md" do
  helpers(ChefDK::Generator::TemplateHelper)
end

# Generated Cookbook:

# cookbook collection dir
directory cookbooks_dir

# cookbook collection dir
directory cookbook_dir

# metadata.rb
template "#{cookbook_dir}/metadata.rb" do
  helpers(ChefDK::Generator::TemplateHelper)
end

# chefignore
cookbook_file "#{cookbook_dir}/chefignore"

# Berks
cookbook_file "#{cookbook_dir}/Berksfile"

# Recipes

directory "#{cookbook_dir}/recipes"

template "#{cookbook_dir}/recipes/default.rb" do
  source "default_recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

# git
if context.have_git

  execute("initialize-git") do
    command("git init .")
    cwd app_dir
  end

  cookbook_file "#{app_dir}/.gitignore" do
    source "gitignore"
  end
end
