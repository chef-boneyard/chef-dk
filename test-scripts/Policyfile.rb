# Policyfile.rb #

name "demo"

default_source :community

run_list "apache2", "omnibus"

cookbook "omnibus", git: "git@github.com:opscode-cookbooks/omnibus.git", branch: "master"

cookbook "homebrew", path: "~/oc/cookbooks/homebrew"

cookbook "build-essential", "= 2.0.0"
