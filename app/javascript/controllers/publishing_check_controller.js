import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['dialogBox', 'agreementCheckbox', 'publishButton', 'curationButton', 'publishText', 'curationText']

  connect () {
    this.agreementCheckboxTarget.removeAttribute('required');
  }


  openDialog(event) {
    let dialogType = event.currentTarget.dataset.dialog
    if (dialogType === 'publish') {
      this.curationButtonTarget.classList.add('d-none');
      this.curationTextTarget.classList.add('d-none');

      this.publishButtonTarget.classList.remove('d-none');
      this.publishTextTarget.classList.remove('d-none');
    } else {
      this.curationButtonTarget.classList.remove('d-none');
      this.curationTextTarget.classList.remove('d-none');

      this.publishButtonTarget.classList.add('d-none');
      this.publishTextTarget.classList.add('d-none');
    }
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
