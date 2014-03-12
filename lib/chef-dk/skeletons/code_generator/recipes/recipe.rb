

context = ChefDK::Generator.context
cookbook_dir = File.join(context.root, context.cookbook_name)
recipe_path = File.join(cookbook_dir, "recipes", "#{context.recipe_name}.rb")

template recipe_path do
  source "recipe.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

