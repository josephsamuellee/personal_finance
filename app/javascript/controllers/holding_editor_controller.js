import { Controller } from "@hotwired/stimulus"

// Reloads a dated holding/price form when the observation date changes.
// With unsaved edits, an inline choice lets the user keep or discard them
// before the date-appropriate values load; clean forms reload directly.
export default class extends Controller {
  static targets = ["date", "bar", "updateButton", "editedField"]

  connect() {
    this.baseline = this.snapshot()
  }

  // Reload the form through a GET submission; the browser serializes all
  // entered fields, so nothing typed so far is lost.
  reload() {
    this.updateButtonTarget.click()
  }

  dateChanged() {
    if (this.hasEdits()) {
      this.barTarget.hidden = false
    } else {
      this.updateButtonTarget.click()
    }
  }

  keepEdits() {
    this.barTarget.hidden = true
    this.updateButtonTarget.click()
  }

  discardEdits() {
    this.barTarget.hidden = true
    this.editedFieldTargets.forEach((field) => { field.value = "" })
    this.updateButtonTarget.click()
  }

  hasEdits() {
    const current = this.snapshot()
    return this.editedFieldTargets.some((field) => current[field.name] !== this.baseline[field.name])
  }

  snapshot() {
    const values = {}
    this.editedFieldTargets.forEach((field) => { values[field.name] = field.value })
    return values
  }
}
