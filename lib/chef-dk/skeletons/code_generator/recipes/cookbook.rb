

context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)

# cookbook root dir
directory cookbook_dir

# metadata.rb
template "#{cookbook_dir}/metadata.rb" do
  helpers(ChefDK::Generator::TemplateHelper)
end

# README
template "#{cookbook_dir}/README.md" do
  helpers(ChefDK::Generator::TemplateHelper)
  variables(:_name => context.cookbook_name)
end

# chefignore
cookbook_file "#{cookbook_dir}/chefignore"

# Berks
cookbook_file "#{cookbook_dir}/Berksfile"

# TK
template "#{cookbook_dir}/.kitchen.yml" do
  source "kitchen.yml"
  helpers(ChefDK::Generator::TemplateHelper)
end

# Recipes

directory "#{cookbook_dir}/recipes"

template "#{cookbook_dir}/recipes/default.rb" do
  source "default_recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

# git
if context.have_git && !context.skip_git_init

  execute("initialize-git") do
    command("git init .")
    cwd cookbook_dir
  end

  cookbook_file "#{cookbook_dir}/.gitignore" do
    source "gitignore"
  end
end


