
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
dot_delivery_dir = File.join(cookbook_dir, ".delivery")

directory dot_delivery_dir

cookbook_file File.join(dot_delivery_dir, "config.json") do
  source "delivery-config.json"
end
