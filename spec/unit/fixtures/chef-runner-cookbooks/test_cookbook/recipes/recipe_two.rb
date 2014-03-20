TestHelpers.test_state[:loaded_recipes] ||= []
TestHelpers.test_state[:loaded_recipes] << "recipe_two"

ruby_block "record_test_result_two" do
  block do
    TestHelpers.test_state[:converged_recipes] ||= []
    TestHelpers.test_state[:converged_recipes] << "recipe_two"
  end
end
