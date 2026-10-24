require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
  end

  test "settings requires a signed-in user" do
    get settings_path
    assert_redirected_to "/session/new"
  end

  test "settings offers appearance choices and no household amounts" do
    sign_in_as(@user)
    get settings_path

    assert_response :success
    assert_select "h2", text: "Appearance"
    assert_select "label", text: /Light/
    assert_select "label", text: /Dark/
    assert_select "label", text: /System/
    assert_select "a[aria-current=page]", count: 0
    assert_not_includes response.body, "Estimated net worth"
    assert_not_includes response.body, "$"
  end

  test "home links to settings at the bottom and in the shell" do
    sign_in_as(@user)
    get root_path

    assert_select "p.mt-8 a[href=?]", settings_path, text: "Settings"
    assert_select "header a[href=?]", settings_path, text: "Settings"
    assert_select "aside a[href=?]", settings_path, text: "Settings"
  end

  test "dark stays dark and light ignores the device" do
    sign_in_as(@user)
    patch settings_path, params: { appearance: "dark" }
    assert_redirected_to settings_path
    assert_equal "dark", @user.reload.appearance

    get settings_path
    assert_select "html[data-appearance=dark]"
    assert_operator response.body.index("applyAppearance"), :<, response.body.index("stylesheet")
    assert_equal "dark", cookies[:appearance]

    patch settings_path, params: { appearance: "light" }
    get root_path
    assert_select "html[data-appearance=light]"
    assert_equal "light", @user.reload.appearance
  end
end
