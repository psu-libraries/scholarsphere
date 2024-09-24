import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['workTypeSelect', 'helpText']

  connect() {
    this.toggleHelpText();
    this.workTypeSelectTarget.addEventListener('change', () => this.toggleHelpText());
  }

  toggleHelpText() {
    if (this.workTypeSelectTarget.value === 'instrument') {
      this.helpTextTarget.style.display = 'block';
    } else {
      this.helpTextTarget.style.display = 'none';
    }
  }
}
