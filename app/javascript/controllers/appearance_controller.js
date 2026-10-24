import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  choose(event) {
    if (!event.target.value) return

    document.documentElement.setAttribute("data-appearance", event.target.value)
    window.applyAppearance?.()
    this.element.requestSubmit()
  }
}
