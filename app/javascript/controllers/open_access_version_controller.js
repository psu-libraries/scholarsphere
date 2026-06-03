import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['versionMessage', 'loading', 'controls', 'timeoutMessage']

  connect() {
    const selectedVersion = this.element.querySelector('input[name="work_version[open_access_version]"]:checked')

    if (selectedVersion) {
      this.refresh({ target: selectedVersion })
    }

    const id = this.data.get('id')

    if (id) {
      this.createSubscription(id)
      this.fetchOpenAccessVersion(id)
      this.timer = setTimeout(() => {
        // Only show timeout message if spinner is still visible and controls are hidden
        const spinnerVisible = this.hasLoadingTarget && !this.loadingTarget.classList.contains('d-none')
        const controlsHidden = this.hasControlsTarget && this.controlsTarget.classList.contains('d-none')

        if (spinnerVisible && controlsHidden) {
          if (this.hasTimeoutMessageTarget && this.timeoutMessageTarget.classList.contains('d-none')) {
            this.timeoutMessageTarget.classList.remove('d-none')
          }
          if (this.hasControlsTarget) this.controlsTarget.classList.remove('d-none')
          if (this.hasLoadingTarget) this.loadingTarget.classList.add('d-none')

          // then unsubscribe from the channel
          if (this.subscription && this.subscription.unsubscribe) {
            try { this.subscription.unsubscribe() } catch (e) { void e }
          }
        }
      }, 30_000)
    }
  }

  disconnect() {
    if (this.subscription && this.subscription.unsubscribe) {
      this.subscription.unsubscribe()
    }
  }

  createSubscription(id) {
    this.subscription = consumer.subscriptions.create(
      { channel: 'OpenAccessVersionChannel', id: id },
      {
        received: (data) => {
          const targetId = this.data.get('id')
          if (String(data.id) !== String(targetId)) return
          this.applyOpenAccessVersion(data.open_access_version)
        }
      }
    )
  }

  fetchOpenAccessVersion(id) {
    fetch(`/dashboard/form/work_versions/${id}/open_access_version`, { headers: { Accept: 'application/json' } })
      .then((response) => {
        if (!response.ok) throw new Error('Network response was not ok')
        return response.json()
      })
      .then((data) => {
        if (!data) return
        this.applyOpenAccessVersion(data.open_access_version)
      })
      .catch(() => void 0)
  }

  applyOpenAccessVersion(open_access_version) {
    if (!open_access_version) return
    const radio = this.element.querySelector(
      `input[name="work_version[open_access_version]"][value="${open_access_version}"]`
    )
    if (radio) {
      radio.checked = true
      this.refresh({ target: radio })
      if (this.hasLoadingTarget) this.loadingTarget.classList.add('d-none')
      if (this.hasControlsTarget) this.controlsTarget.classList.remove('d-none')
    }
  }

  refresh(event) {
    const version = event.target.value

    const key = version

    // autopopulate open access fields based on selected version
    const rights = this.data.get(`${key}Rights`)
    const statement = this.data.get(`${key}Statement`)
    const embargo = this.data.get(`${key}Embargo`)

    const statementInput = document.getElementById('work_version_publisher_statement')
    const embargoInput = document.getElementById('work_version_work_attributes_embargoed_until')
    // select fields don't have readonly, only disabled so to disable the rights input & 
    // prevent user changes when autopopulated, we need to use a hidden field to submit the value
    const rightsHidden = document.getElementById('work_version_rights_hidden')
    // this is still set to control what the user sees, but it is not the value that is submitted
    const rightsInput = document.getElementById('work_version_rights')


    if (rightsInput) rightsInput.value = rights || ''
    if (rightsHidden) rightsHidden.value = rights || ''
    if (statementInput) statementInput.value = statement || ''
    if (embargoInput) embargoInput.value = embargo || ''

    // display message when there is a version mismatch
    const versionsFound = JSON.parse(this.data.get('versionsFound'))
    const acceptedVersion = this.data.get('acceptedVersionValue')
    const publishedVersion = this.data.get('publishedVersionValue')
    const otherVersion = version === acceptedVersion ? publishedVersion : acceptedVersion
    const currentVersionFound = versionsFound.includes(version)
    const otherVersionFound = versionsFound.includes(otherVersion)
    const label = {
      [acceptedVersion]: this.data.get('acceptedVersionLabel'),
      [publishedVersion]: this.data.get('publishedVersionLabel')
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