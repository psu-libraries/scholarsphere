import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['source']

  copy () {
    navigator.clipboard.writeText(this.sourceTarget.dataset.source)
  }
}
