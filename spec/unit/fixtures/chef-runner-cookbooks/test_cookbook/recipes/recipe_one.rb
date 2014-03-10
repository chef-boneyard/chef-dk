TestHelpers.test_state[:loaded_recipes] ||= []
TestHelpers.test_state[:loaded_recipes] << "recipe_one"

ruby_block "record_test_result_one" do
  block do
    TestHelpers.test_state[:converged_recipes] ||= []
    TestHelpers.test_state[:converged_recipes] << "recipe_one"
  end
end
