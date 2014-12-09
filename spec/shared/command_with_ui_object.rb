shared_examples_for "a command with a UI object" do

  subject(:command) { described_class.new }

  it "configures a default UI component" do
    ui = command.ui
    expect(ui.out_stream).to eq($stdout)
    expect(ui.err_stream).to eq($stderr)
  end

end
