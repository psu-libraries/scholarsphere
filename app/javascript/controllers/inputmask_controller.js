import { Controller } from 'stimulus'
import Inputmask from 'inputmask'

export default class extends Controller {
  // Presently, there is only one input mask: orcid. So there isn't the need (yet) to try to apply different types of
  // masks based on the input type or id.
  connect () {
    const im = new Inputmask('9999-9999-9999-999X', {
      definitions: {
        X: {
          validator: '[0-9xX]',
          casing: 'upper'
        }
      },
      removeMaskOnSubmit: true
    })
    im.mask(this.element)
  }
}
