// @abstract Calls focus to the form error message

import { Controller } from 'stimulus'

export default class extends Controller {
  connect () {
    setTimeout(() => {
      this.element.focus()
    }, 100)
  }
}
