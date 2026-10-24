import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { focus: String }

  connect() {
    if (this.sheetOnScreen()) return

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.element.scrollIntoView({ block: "nearest", behavior: reduce ? "auto" : "smooth" })
    const target = (this.hasFocusValue && document.getElementById(this.focusValue)) || this.element.querySelector("h2, h3, input")
    if (!target) return

    if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1")
    target.focus()
  }

  sheetOnScreen() {
    return this.element.classList.contains("max-lg:fixed") && window.matchMedia("(max-width: 1023px)").matches
  }
}
