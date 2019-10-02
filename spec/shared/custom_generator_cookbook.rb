
# Required `let` bindings:
# * `generator_name` in lowercase, e.g., "cookbook", "app"
# * `generator_arg`: argument to the generator command
# * `expected_cookbook_files`: a list of files the generator should create
shared_examples_for "custom generator cookbook" do

  context "when given a generator-cookbook path" do

    let(:default_generator_cookbook_path) { File.expand_path("lib/chef-dk/skeletons/code_generator", project_root) }

    let(:generator_cookbook_path) { File.join(tempdir, "a_generator_cookbook") }
    let(:generator_copyright_holder) { "Chef" }
    let(:generator_email) { "mail@chef.io" }
    let(:generator_license) { "Free as in Beer" }

    let(:argv) { [generator_arg, "--generator-cookbook", generator_cookbook_path] }

    let(:stdout_io) { StringIO.new }

    subject(:code_generator) do
      described_class.new(argv).tap do |gen|
        allow(gen).to receive(:stdout).and_return(stdout_io)
      end
    end

    before do
      reset_tempdir
      code_generator.read_and_validate_params
      allow(code_generator.config_loader).to receive(:load)
    end

    it "configures the generator context" do
      code_generator.setup_context
      expect(generator_context.cookbook_name).to eq(generator_arg)
      expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
      expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])
    end

    context "when the generator cookbook is configured in a configuration file" do

      let(:argv) { [generator_arg] }

      let(:generator_config) do
        double("Generator Config Context",
          license: generator_license,
          copyright_holder: generator_copyright_holder,
          email: generator_email)
      end

      let(:chefdk_config) do
        double("Mixlib::Config context for ChefDK",
          generator_cookbook: generator_cookbook_path,
          generator: generator_config)
      end

      before do
        allow(code_generator).to receive(:chefdk_config).and_return(chefdk_config)
      end

      it "configures the generator context" do
        code_generator.setup_context
        expect(generator_context.cookbook_name).to eq(generator_arg)
        expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
        expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])
      end
    end

    context "with an invalid generator-cookbook path" do

      it "fails with an informative error" do
        Dir.chdir(tempdir) do
          allow(code_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          allow(code_generator).to receive(:stderr).and_return(stderr_io)
          expect(code_generator.run).to eq(1)
        end

        cookbook_path = File.dirname(generator_cookbook_path)
        expected_msg = %Q{ERROR: Could not find cookbook(s) to satisfy run list ["recipe[a_generator_cookbook::#{generator_name}]"] in #{cookbook_path}}

        expect(stderr_io.string).to include(expected_msg)
      end

    end

    context "with a generator-cookbook path to a specific cookbook" do

      let(:metadata_file) { File.join(generator_cookbook_path, "metadata.rb") }

      before do
        FileUtils.cp_r(default_generator_cookbook_path, generator_cookbook_path)

        # have to update metadata with the correct name
        IO.binwrite(metadata_file, "name 'a_generator_cookbook'")
      end

      it "creates the new files" do
        expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
        expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])

        Dir.chdir(tempdir) do
          allow(code_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          code_generator.run
        end
      end

    end

    context "with a generator-cookbook path to a directory containing a 'code_generator' cookbook" do

      before do
        FileUtils.mkdir_p(generator_cookbook_path)
        FileUtils.cp_r(default_generator_cookbook_path, generator_cookbook_path)

        allow(code_generator).to receive(:stderr).and_return(stderr_io)
      end

      it "creates the new_files (and warns about deprecated usage)" do
        allow(code_generator.chef_runner).to receive(:stdout).and_return(stdout_io)

        Dir.chdir(tempdir) do
          code_generator.run
        end
        generated_files = Dir.glob("#{tempdir}/#{generator_arg}/**/*", File::FNM_DOTMATCH)
        expected_cookbook_files.each do |expected_file|
          expect(generated_files).to include(expected_file)
        end

        code_generator_path = File.join(generator_cookbook_path, "code_generator")
        warning_message = "WARN: Please configure the generator cookbook by giving the full path to the desired cookbook (like '#{code_generator_path}')"

        expect(stderr_io.string).to include(warning_message)
      end
    end
  end
end
