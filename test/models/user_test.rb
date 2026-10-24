require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "a new user defaults to the system appearance" do
    user = User.create!(
      email_address: "cara@example.com",
      password: "password-password",
      password_confirmation: "password-password"
    )

    assert_equal "system", user.reload.appearance
  end

  test "appearance must be system, light, or dark" do
    user = create_user
    user.appearance = "sepia"

    assert_not user.valid?
    assert_includes user.errors[:appearance], "is not included in the list"
  end
end
