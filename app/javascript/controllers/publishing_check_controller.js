import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['dialogBox',
    'agreementCheckbox',
    'psuCommunityCheckbox',
    'accessibilityCheckbox',
    'sensitiveInfoCheckbox',
    'publishButton',
    'curationButton',
    'publishText',
    'curationText']

  checkBoxTargets = [this.agreementCheckboxTarget,
    this.psuCommunityCheckboxTarget,
    this.accessibilityCheckboxTarget,
    this.sensitiveInfoCheckboxTarget]

  connect () {
    // We only want to require the checkbox if the dialog is open.
    if (this.checkBoxTargets.length > 0) {
      for (let checkbox of this.checkBoxTargets) {
        checkbox.removeAttribute('required');
      }
    }
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
    // We need to bind the tooltip to the modal, other it will not be visible.
    $('[data-toggle="modal-tooltip"]').tooltip({container: "#hidden-publish-dialog"});
    this.dialogBoxTarget.showModal();
    // We only want to require the checkbox if the dialog is open.
    // If the checkbox is required when the dialog is closed, the Save and Exit button will not work.
    for (let checkbox of this.checkBoxTargets) {
      checkbox.setAttribute('required', 'required');
    }
}

  closeDialog () {
    for (let checkbox of this.checkBoxTargets) {
      checkbox.removeAttribute('required');
    } 

    this.dialogBoxTarget.close();
  }
}
