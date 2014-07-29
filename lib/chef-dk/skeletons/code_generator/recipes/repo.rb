context = ChefDK::Generator.context
repo_dir = File.join(context.repo_root, context.repo_name)

# repo root dir
directory repo_dir

# Top level files
template "#{repo_dir}/LICENSE" do
  source "LICENSE.#{context.license}.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

cookbook_file "#{repo_dir}/README.md" do
  source "repo/README.md"
end

cookbook_file "#{repo_dir}/Rakefile" do
  source "repo/Rakefile"
end

cookbook_file "#{repo_dir}/chefignore" do
  source "chefignore"
end

directory "#{repo_dir}/config"

template "#{repo_dir}/config/rake.rb" do
  source "repo/config/rake.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

%w{certificates data_bags environments roles}.each do |tlo|
  directory "#{repo_dir}/#{tlo}"

  cookbook_file "#{repo_dir}/#{tlo}/README.md" do
    source "repo/#{tlo}/README.md"
  end
end

directory "#{repo_dir}/cookbooks"

cookbook_file "#{repo_dir}/cookbooks/README.md" do
  if context.policy_only
    source "repo/cookbooks/README-policy.md"
  else
    source "repo/cookbooks/README.md"
  end
end

# git
if context.have_git
  execute("initialize-git") do
    command("git init .")
    cwd repo_dir
    not_if { "#{repo_dir}/.gitignore" }
  end

  template "#{repo_dir}/.gitignore" do
    source "repo/gitignore.erb"
    helpers(ChefDK::Generator::TemplateHelper)
  end
end
