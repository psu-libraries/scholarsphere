import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['altTextField', 'successIcon', 'errorIcon'];

  onPostSuccess (event) {
    const [data] = event.detail
    this.altTextFieldTarget.value = data.alt_text
    this.showSuccessIcon()
  };

  showSuccessIcon () {
    this.successIconTarget.classList.add('show')
    setTimeout(() => {
      this.successIconTarget.classList.remove('show')
    }, 2000)
  };

  onPostError (event) {
    const [data] = event.detail
    console.log(data.errors)
    this.altTextFieldTarget.value = data.alt_text
    this.showErrorIcon()
  };

  showErrorIcon () {
    this.errorIconTarget.classList.add('show')
    setTimeout(() => {
      this.errorIconTarget.classList.remove('show')
    }, 2000)
  };
};
