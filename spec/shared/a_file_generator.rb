shared_examples_for "a file generator" do

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  let(:expected_cookbook_root) { tempdir }
  let(:cookbook_name) { "example_cookbook" }

  let(:cookbook_path) { File.join(tempdir, cookbook_name) }

  subject(:recipe_generator) do
    generator = described_class.new(argv)
    allow(generator).to receive(:stdout).and_return(stdout_io)
    allow(generator).to receive(:stderr).and_return(stderr_io)
    generator
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
    reset_tempdir
  end

  after(:each) do
    ChefDK::Generator::Context.reset
  end

  context "when argv is empty" do
    let(:argv) { [] }

    it "emits an error message and exits" do
      expected_stdout = "Usage: chef generate #{generator_name} [path/to/cookbook] NAME [options]"

      expect(recipe_generator.run).to eq(1)
      expect(stdout).to include(expected_stdout)
    end
  end

  context "when CWD is a cookbook" do

    let(:argv) { [ new_file_name ] }

    before do
      FileUtils.cp_r(File.join(fixtures_path, "example_cookbook"), tempdir)
    end

    it "configures the generator context" do
      Dir.chdir(cookbook_path) do
        recipe_generator.read_and_validate_params
        recipe_generator.setup_context

        expect(generator_context.cookbook_root).to eq(expected_cookbook_root)
        expect(generator_context.cookbook_name).to eq(cookbook_name)
        expect(generator_context.new_file_basename).to eq(new_file_name)
        expect(generator_context.recipe_name).to eq(new_file_name)
      end
    end

    it "creates a new recipe" do
      Dir.chdir(cookbook_path) do
        allow(recipe_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        recipe_generator.run
      end

      generated_files.each do |expected_file|
        expect(File).to exist(File.join(cookbook_path, expected_file))
      end
    end

  end

  context "when CWD is not a cookbook" do
    context "and path to the cookbook is not given in the agv" do
      let(:argv) { [ new_file_name ] }

      it "emits an error message and exits" do
        expected_stdout = "Usage: chef generate #{generator_name} [path/to/cookbook] NAME [options]"
        expected_stderr = "Error: Directory #{Dir.pwd} is not a cookbook\n"

        expect(recipe_generator.run).to eq(1)
        expect(stdout).to include(expected_stdout)
        expect(stderr).to eq(expected_stderr)
      end
    end

    context "and path to the cookbook is given in the argv" do
      let(:argv) { [cookbook_path, new_file_name ] }

      before do
        FileUtils.cp_r(File.join(fixtures_path, "example_cookbook"), tempdir)
      end

      it "configures the generator context" do
        recipe_generator.read_and_validate_params
        recipe_generator.setup_context

        expect(generator_context.cookbook_root).to eq(File.dirname(cookbook_path))
        expect(generator_context.cookbook_name).to eq(cookbook_name)
        expect(generator_context.new_file_basename).to eq(new_file_name)
      end

      it "creates a new recipe" do
        allow(recipe_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        recipe_generator.run

        generated_files.each do |expected_file|
          expect(File).to exist(File.join(cookbook_path, expected_file))
        end
      end

    end
  end

end
