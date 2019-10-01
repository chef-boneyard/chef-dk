context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
libraries_dir = File.join(cookbook_dir, 'libraries')
helpers_path = File.join(cookbook_dir, 'libraries', "#{context.new_file_basename}.rb")

directory libraries_dir

def camelize(name)
  name.to_s.split(/[^a-zA-Z]/).map(&:capitalize).join
end

cookbook_class_name = camelize(context.cookbook_name)
helper_class_name = "#{camelize(context.new_file_basename)}Helpers"

template helpers_path do
  source 'helpers.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
  variables(cookbook_class_name: cookbook_class_name, helper_class_name: helper_class_name)
end
