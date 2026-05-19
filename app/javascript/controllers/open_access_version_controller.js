import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['versionMessage']

  connect() {
    const selectedVersion = this.element.querySelector('input[name="work_version[open_access_version]"]:checked')
    if (selectedVersion) {
      this.refresh({ target: selectedVersion })
    }
  }

  refresh(event) {
    const version = event.target.value

    const key = version

    // autopopulate open access fields based on selected version
    const rights = this.data.get(`${key}Rights`)
    const statement = this.data.get(`${key}Statement`)
    const embargo = this.data.get(`${key}Embargo`)

    const rightsInput = document.getElementById('work_version_rights')
    const statementInput = document.getElementById('work_version_publisher_statement')
    const embargoInput = document.getElementById('work_version_work_attributes_embargoed_until')
    // select fields don't have readonly, only disabled so to disable the rights input & 
    // prevent user changes when autopopulated, we need to use a hidden field to submit the value
    const rightsHidden = document.getElementById('work_version_rights_hidden')

    if (rightsInput) rightsInput.value = rights || ''
    if (rightsHidden) rightsHidden.value = rights || ''
    if (statementInput) statementInput.value = statement || ''
    if (embargoInput) embargoInput.value = embargo || ''

    // display message when there is a version mismatch
    const versionsFound = JSON.parse(this.data.get('versionsFound'))
    const otherVersion = version === 'acceptedVersion' ? 'publishedVersion' : 'acceptedVersion'
    const currentVersionFound = versionsFound.includes(version)
    const otherVersionFound = versionsFound.includes(otherVersion)
    const label = {
      acceptedVersion: 'accepted version',
      publishedVersion: 'published version'
    }
    const message = this.data.get('otherMessage')

    if (currentVersionFound) {
      this.versionMessageTarget.textContent = ''
    } else if (otherVersionFound) {
      this.versionMessageTarget.textContent = message
        .replace(/__THIS__/g, label[version])
        .replace(/__OTHER__/g, label[otherVersion])
    } else {
      this.versionMessageTarget.textContent = this.data.get('notFoundMessage')
    }

    // block publish when there is a version mismatch
    const versionAllowed = version == null || version === '' || currentVersionFound
    setTimeout(() => {
      document.dispatchEvent(new CustomEvent('open-access:version-updated', {
        detail: { versionAllowed }
      }))
    }, 0)
  }
}