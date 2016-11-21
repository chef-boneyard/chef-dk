
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
libraries_dir = File.join(cookbook_dir, "libraries")
helpers_path = File.join(cookbook_dir, "libraries", "#{context.new_file_basename}.rb")

directory libraries_dir

cookbook_class_name = context.cookbook_name.split(/[^a-zA-Z]/).map {|i| i.capitalize }.join
helper_class_name = "#{context.new_file_basename.capitalize}Helpers"

template helpers_path do
  source "helpers.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  variables(cookbook_class_name: cookbook_class_name, helper_class_name: helper_class_name)
end
