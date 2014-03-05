

app = ChefDK::Generator.app

# cookbook root dir
directory app.root

# metadata.rb
template "#{app.root}/metadata.rb" do
  helpers(ChefDK::Generator::TemplateHelper)
end

# README
template "#{app.root}/README.md" do
  helpers(ChefDK::Generator::TemplateHelper)
end

# chefignore
cookbook_file "#{app.root}/chefignore"

# Berks
cookbook_file "#{app.root}/Berksfile"

# TK
template "#{app.root}/.kitchen.yml" do
  source "kitchen.yml"
  helpers(ChefDK::Generator::TemplateHelper)
end

# Recipes

directory "#{app.root}/recipes"

template "#{app.root}/recipes/default.rb" do
  source "default_recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

# git
if system("git --version")

  execute("initialize-git") do
    command("git init .")
    cwd app.root
  end

  cookbook_file "#{app.root}/.gitignore" do
    source "gitignore"
  end
end


