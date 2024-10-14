import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [
    'dialogBox',
    'agreementCheckbox',
    'psuCommunityCheckbox',
    'accessibilityCheckbox',
    'sensitiveInfoCheckbox',
    'publishButton',
    'curationButton',
    'remediationButton',
    'publishText',
    'curationText',
    'remediationText'
  ]

  checkBoxTargets = [
    this.agreementCheckboxTarget,
    this.psuCommunityCheckboxTarget,
    this.accessibilityCheckboxTarget,
    this.sensitiveInfoCheckboxTarget
  ]

  allDisplayTargets = [
    this.publishButtonTarget,
    this.publishTextTarget,
    this.curationButtonTarget,
    this.curationTextTarget,
    this.remediationButtonTarget,
    this.remediationTextTarget
  ]

  displayTargetMap = {
    'publish': [
      this.publishButtonTarget,
      this.publishTextTarget
    ],
    'curation': [
      this.curationButtonTarget,
      this.curationTextTarget
    ],
    'remediation': [
      this.remediationButtonTarget,
      this.remediationTextTarget
    ]
  }

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
    let currentTypeTargets = this.displayTargetMap[dialogType]
    // Hide all the targets that are not part of the current dialog.
    for (let t of this.allDisplayTargets) {
      if (currentTypeTargets.includes(t)) {
        t.classList.remove('d-none');
      } else {
        t.classList.add('d-none');
      }
    }

    // Bind the tooltip to the dialog object, other it will not be visible.
    $('[data-toggle="modal-tooltip"]').tooltip({container: "#hidden-publish-dialog"});
    this.dialogBoxTarget.showModal();

    // We only want to require the checkbox if the dialog is open.
    // Otherwise, the Save and Exit button will not work.
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
