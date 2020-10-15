import { Controller } from 'stimulus'
import axios from 'axios'
import { csrfToken } from './stimulus_modules'

export default class extends Controller {
  connect () {
    document.addEventListener('autocomplete:alternative', () => this.openModal(this.data.get('new')))
    document.addEventListener('autocomplete:after-selected', () => this.post(this.data.get('post')))
    document.addEventListener('actor:created', () => this.appendResponse(event.detail.response))

    this.badgeClass = this.data.get('badge-class')

    // @todo This uses jQuery. We might want to put these in a separate location for better organization
    this.renumberBadges = () => {
      $(this.element)
        .find(`.${this.badgeClass}:visible`)
        .each((index, item) => {
          $(item).text(index + 1)
        })
    }

    $(this.element).on('cocoon:after-remove', () => this.renumberBadges())
  }

  post (url) {
    axios({
      method: 'POST',
      url: url,
      data: event.detail.suggestion,
      headers: {
        'X-CSRF-Token': csrfToken()
      }
    })
      .then(response => this.appendResponse(response))
      .catch(error => this.processError(error))
  }

  appendResponse (response) {
    this.element.insertAdjacentHTML('beforeend', response.data)
    this.renumberBadges()
  }

  // @todo Something nicer should go here.
  processError (error) {
    console.log(error)
  }

  openModal (url) {
    axios.get(url)
      .then(function (response) {
        Blacklight.modal.receiveAjax(response.data) // eslint-disable-line no-undef
      })
      .catch(function (error) {
        console.log(error)
      })
  }
}
