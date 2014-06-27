
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
attribute_dir = File.join(cookbook_dir, "attributes")
attribute_path = File.join(cookbook_dir, "attributes", "#{context.new_file_basename}.rb")

directory attribute_dir

template attribute_path do
  source "attribute.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end
