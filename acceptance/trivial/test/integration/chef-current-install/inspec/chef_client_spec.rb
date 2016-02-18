chef_version = ENV["KITCHEN_CHEF_VERSION"].split("+")[0]
describe command("chef -v") do
  its("exit_status") { should eq 0 }
  its(:stdout) { should match /Chef Development Kit Version: #{chef_version}/ } if chef_version != "latest"
end
