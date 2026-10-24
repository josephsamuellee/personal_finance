import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { returnFocus: String }

  connect() {
    this.element.querySelector("input, select, textarea")?.focus()
  }

  close(event) {
    event.preventDefault()
    this.element.hidden = true
    document.getElementById(this.returnFocusValue)?.focus()
  }
}
