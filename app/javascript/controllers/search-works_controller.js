import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['field']

  connect () {
    $(this.fieldTarget).select2({
      templateSelection: (state) => {
        if (state.id !== '') {
          const suggestion = { work_id: state.id }
          this.element.dispatchEvent(this.afterSelectedEvent(suggestion))
        }
      }
    })
  }

  afterSelectedEvent (suggestion) {
    return new CustomEvent('autocomplete:after-selected', { bubbles: true, detail: { suggestion: suggestion } })
  }
}
