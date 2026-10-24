require "application_system_test_case"

class AppearanceTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1440, 900]

  test "dark applies without a manual reload and the chart uses that text color" do
    visit new_user_path
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"
    assert_selector "h1", text: "Home"

    account = Account.create!(name: "Cash", account_type: "checking", currency: "USD")
    user = User.find_by!(email_address: "ada@example.com")
    AccountObservation.revise_current!({ account: }, observed_on: Date.current, updated_by: user, amount: 25)

    visit settings_path
    choose "Dark"

    assert_selector "html.dark", visible: :all
    assert_equal "dark", page.evaluate_script("document.documentElement.getAttribute('data-appearance')")

    visit root_path
    assert_selector "[data-controller=chart]"
    colors = page.evaluate_script(<<~JS)
      JSON.stringify({
        body: getComputedStyle(document.body).color,
        chart: document.querySelector("[data-controller=chart]").dataset.chartTextColor
      })
    JS
    parsed = JSON.parse(colors)
    assert_equal parsed["body"], parsed["chart"]
    assert_not_equal "rgb(51, 51, 51)", parsed["chart"]

    series = JSON.parse(page.evaluate_script(<<~JS))
      (() => {
        const chart = document.querySelector("[data-chart-mode-value=spending]")
        const probe = document.createElement("span")
        probe.style.color = "var(--color-sky-700)"
        document.body.appendChild(probe)
        const light = getComputedStyle(probe).color
        probe.remove()
        return JSON.stringify({ bar: chart.dataset.chartBarColor, light })
      })()
    JS
    assert_not_equal series["light"], series["bar"]
  end

  test "dark navigation link has a 4px band and a visible focus ring" do
    visit new_user_path
    fill_in "Email", with: "band@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"
    assert_selector "h1", text: "Home"

    visit settings_path
    choose "Dark"
    assert_selector "html.dark", visible: :all

    visit root_path
    colors = page.evaluate_script(<<~JS)
      (() => {
        const link = document.querySelector("aside a.ui-nav")
        const card = document.querySelector(".ui-card")
        const probe = document.createElement("div")
        probe.style.backgroundColor = "var(--color-slate-700)"
        document.body.appendChild(probe)
        const band = getComputedStyle(probe).backgroundColor
        probe.remove()
        const before = getComputedStyle(link).boxShadow
        link.focus({ focusVisible: true })
        const focused = getComputedStyle(link)
        return JSON.stringify({
          shadow: focused.boxShadow,
          before: before,
          margin: focused.marginTop,
          band: band,
          card: getComputedStyle(card).backgroundColor,
          focused: link.matches(":focus-visible")
        })
      })()
    JS
    parsed = JSON.parse(colors)
    assert_includes parsed["shadow"], "4px"
    assert_equal "4px", parsed["margin"]
    assert parsed["focused"], "expected the navigation link to show a visible focus ring"
    assert_not_equal parsed["before"], parsed["shadow"]
    assert_not_equal parsed["band"], parsed["card"]
  end
end