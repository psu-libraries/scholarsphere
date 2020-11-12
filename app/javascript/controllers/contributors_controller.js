import { Controller } from 'stimulus'
import axios from 'axios'
import { csrfToken } from './stimulus_modules'

export default class extends Controller {
  connect () {
    this.wrapperClass = this.data.get('wrapper-class')
    this.badgeClass = this.data.get('badge-class')
    this.positionClass = this.data.get('position-class')

    document.addEventListener('autocomplete:alternative', () => this.openModal(this.data.get('new')))
    document.addEventListener('autocomplete:after-selected', () => this.post(this.data.get('post')))
    document.addEventListener('actor:created', () => this.appendResponse(event.detail.response))

    $(this.element).on('cocoon:after-remove', () => this.$updateChildren())

    this.$updateChildren()
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
    this.$updateChildren()
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

  moveUp (event) {
    const $target = $(event.target)
    const $parentWrapper = $target.closest(`.${this.wrapperClass}`)
    const $previousSibling = $parentWrapper.prevAll(`.${this.wrapperClass}:visible`).first()

    if ($previousSibling.length > 0) {
      this._$swapElements($parentWrapper, $previousSibling)
      this.$updateChildren()
    }
  }

  moveDown (event) {
    const $target = $(event.target)
    const $parentWrapper = $target.closest(`.${this.wrapperClass}`)
    const $nextSibling = $parentWrapper.nextAll(`.${this.wrapperClass}:visible`).first()

    if ($nextSibling.length > 0) {
      this._$swapElements($parentWrapper, $nextSibling)
      this.$updateChildren()
    }
  }

  // Uses jQuery
  $updateChildren () {
    const children = $(this.element)
      .find(`.${this.wrapperClass}:visible`)

    children
      .each((index, wrapperElement) => {
        $(wrapperElement).find(`.${this.badgeClass}`).text(index + 1)
        $(wrapperElement).find(`.${this.positionClass}`).val((index + 1) * 10)
        $(wrapperElement).find('.js-move-up').toggleClass('disabled', index === 0)
        $(wrapperElement).find('.js-move-down').toggleClass('disabled', index === children.length - 1)
      })
  }

  // Uses jQuery
  _$swapElements ($el1, $el2) {
    // create temporary placeholder
    const $temp = $('<div>')

    // 3-step swap
    $el1.before($temp)
    $el2.before($el1)
    $temp.after($el2).remove()
  }
}
