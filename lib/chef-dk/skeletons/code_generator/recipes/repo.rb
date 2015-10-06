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

cookbook_file "#{repo_dir}/chefignore" do
  source "chefignore"
end

%w{cookbooks data_bags environments roles}.each do |tlo|
  remote_directory "#{repo_dir}/#{tlo}" do
    source "repo/#{tlo}"
  end
end

cookbook_file "#{repo_dir}/cookbooks/README.md" do
  if context.policy_only
    source "cookbook_readmes/README-policy.md"
  else
    source "cookbook_readmes/README.md"
  end
end

# git
if context.have_git
  execute("initialize-git") do
    command("git init .")
    cwd repo_dir
    not_if { File.exist?("#{repo_dir}/.gitignore") }
    ## if we're already in a git repo, dont init.
    ## exits 0 if we're in a repo, 128 if we're not.
    not_if "git rev-parse"
  end

  template "#{repo_dir}/.gitignore" do
    source "repo/gitignore.erb"
    helpers(ChefDK::Generator::TemplateHelper)
  end
end
