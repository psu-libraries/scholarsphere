import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['titleStatic', 'form', 'titleField', 'errorsContainer']

  connect() {
    this.formTarget.style.display = 'none'
  }

  showForm(event) {
    event && event.preventDefault()
    this.titleFieldTarget.value = this.titleStaticTarget.textContent
    this.formTarget.style.display = ''
    this.titleStaticTarget.style.display = 'none'
    this.errorsContainerTarget.style.display = 'none'
  }

  hideForm(event) {
    event && event.preventDefault()
    this.formTarget.style.display = 'none'
    this.titleStaticTarget.style.display = ''
  }

  toggleForm(event) {
    this.formTarget.style.display === 'none' ? this.showForm(event) : this.hideForm(event)
  }

  onPostSuccess(event) {
    let [ fileVersionMembership ] = event.detail
    this.titleStaticTarget.textContent = fileVersionMembership.title
    this.hideForm()
  }

  onPostError(event) {
    let errorsList = this.errorsContainerTarget.querySelector('ul')
    let [ errors ] = event.detail
    let errorFullMessages = Object.keys(errors)
      .map(attribute => [attribute, errors[attribute]] )
      .flatMap(([attribute, messages]) => {
        return messages.map(message => `${attribute} ${message}`)
      })

    this.errorsContainerTarget.style.display = ''

    errorsList.innerHTML = errorFullMessages.map(msg => `<li>${msg}</li>`)
  }
}
