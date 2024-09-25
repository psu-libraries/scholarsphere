import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['dialogBox', 'agreementCheckbox']


  openDialog () {
    this.dialogBoxTarget.showModal();
    // We only want to require the checkbox if the dialog is open.
    // If the checkbox is required when the dialog is closed, the Save and Exit button will not work.
    this.agreementCheckboxTarget.setAttribute('required', 'required');
}

  closeDialog () {
    this.dialogBoxTarget.close();
    this.agreementCheckboxTarget.removeAttribute('required');
  }
}
