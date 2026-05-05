import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['workTypeSelect', 'helpText', 'openAccess']

  connect () {
    this.toggleHelpText()
    this.workTypeSelectTarget.addEventListener('change', () => this.toggleHelpText())
  }

  toggleHelpText () {
    const value = this.workTypeSelectTarget.value

    if (value === "instrument") {
      this.helpTextTarget.style.display = "block"
    } else {
      this.helpTextTarget.style.display = "none"
    }
    if (JSON.parse(this.data.get('oaTypesValue')).includes(value)) {
      this.openAccessTarget.style.display = "block"
    } else {
      this.openAccessTarget.style.display = "none"
    }
  }
}
