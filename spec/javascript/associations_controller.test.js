import { Application } from 'stimulus'
import AssociationsController from 'associations_controller'
import $ from 'jquery'

window.$ = $
window.jQuery = $

describe('AssociationsController', () => {
  let element, input

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="associations">
        <div id="to-remove">
          <input type="text" required="required" />
        </div>
      </div>
    `
    element = document.querySelector('[data-controller="associations"]')
    input = document.querySelector('#to-remove input')
    const app = Application.start()
    app.register('associations', AssociationsController)
  })

  it('removes required attribute from fields in the removed element on cocoon:before-remove', () => {
    // Simulate cocoon:before-remove event
    $(element).trigger('cocoon:before-remove', [$('#to-remove')])
    expect(input.hasAttribute('required')).toBe(false)
  })
})