
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
recipe_path = File.join(cookbook_dir, "recipes", "#{context.new_file_basename}.rb")

template recipe_path do
  source "recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end
