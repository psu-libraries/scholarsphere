import { Controller } from 'stimulus'
import axios from 'axios'
import { csrfToken } from './stimulus_modules'

export default class extends Controller {
  connect () {
    this.redirect = this.data.get('redirect')
  }

  // Intercept Rails UJS's ajax:success callback and update the modal with the resulting content.
  // This avoids having to have a separate .js.erb partial in a typical Rails AJAX setup.
  success (event) {
    const [data, status, xhr] = event.detail // eslint-disable-line no-unused-vars
    event.preventDefault()
    this.post(data)
  }

  post (data) {
    axios({
      method: 'POST',
      url: this.redirect,
      data: data,
      headers: {
        'X-CSRF-Token': csrfToken()
      }
    })
      .then(response => this.created(response))
      .catch(error => this.processError(error))
  }

  created (response) {
    this.element.dispatchEvent(new CustomEvent('actor:created', { bubbles: true, detail: { response: response } }))
    $(Blacklight.modal.modalSelector).modal('hide') // eslint-disable-line no-undef
  }

  // @todo Something nicer should go here.
  processError (error) {
    console.log(error)
  }
}
