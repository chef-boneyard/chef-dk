shared_examples_for "a generated file" do |context_var|
  before do
    Dir.chdir(tempdir) do
      allow(generator.chef_runner).to receive(:stdout).and_return(stdout_io)
      generator.run
    end
  end

  it "should contain #{context_var} from the generator context" do
    expect(File.read(file)).to match line
  end
end
