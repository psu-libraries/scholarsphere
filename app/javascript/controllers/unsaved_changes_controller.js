import { Controller } from 'stimulus'
import formChanges from '../vendor/formchanges.js'

export default class extends Controller {
  static targets = ['form']

  connect () {
    this.promptText = this.data.get('prompt')
  }

  prompt (event) {
    const hasChanges = formChanges(this.formTarget).length > 0
    if (!hasChanges) { return true }

    const discard = confirm(this.promptText)

    if (discard) {
      return true
    } else {
      event.preventDefault()
    }
  }
}
