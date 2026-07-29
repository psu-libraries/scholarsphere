import { Controller } from 'stimulus'
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = ['versionMessage', 'fieldUpdates', 'loading', 'controls']

  connect() {
    const selectedVersion = this.element.querySelector('input[name="work_version[open_access_version]"]:checked')

    if (selectedVersion) {
      this.refresh({ target: selectedVersion })
    }

    const id = this.data.get('id')

    if (id) {
      this.createSubscription(id)
      this.fetchOpenAccessVersion(id)
      this.startTimer(id)
    }
  }

  disconnect() {
    if (this.timerHandle) {
      clearTimeout(this.timerHandle)
      this.timerHandle = null
    }

    if (this.subscription && this.subscription.unsubscribe) {
      this.subscription.unsubscribe()
    }

    if (this.clearHighlightHandle) {
      clearTimeout(this.clearHighlightHandle)
      this.clearHighlightHandle = null
    }
  }

  createSubscription(id) {
    this.subscription = consumer.subscriptions.create(
      { channel: 'OpenAccessVersionChannel', id: id },
      {
        received: (data) => {
          if (String(data.id) !== String(id)) return
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

  startTimer(id) {
    this.timerHandle = setTimeout(() => {
      const spinnerVisible = this.hasLoadingTarget && !this.loadingTarget.classList.contains('d-none')
      const controlsHidden = this.hasControlsTarget && this.controlsTarget.classList.contains('d-none')

      if (spinnerVisible && controlsHidden) {
        if (this.hasControlsTarget) this.controlsTarget.classList.remove('d-none')
        if (this.hasLoadingTarget) this.loadingTarget.classList.add('d-none')
        this.fetchOpenAccessVersion(id)
      }

      if (this.subscription && this.subscription.unsubscribe) {
        try { this.subscription.unsubscribe() } catch (e) { void e }
      }
    }, 15_000)
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

    const changedFields = []

    const rightsChanged = this.updateInputValue(rightsInput, rights)
    this.updateInputValue(rightsHidden, rights)
    if (rightsChanged) {
      changedFields.push(this.data.get('rightsLabel'))
      this.markFieldAsUpdated(rightsInput)
    }

    const statementChanged = this.updateInputValue(statementInput, statement)
    if (statementChanged) {
      changedFields.push(this.data.get('statementLabel'))
      this.markFieldAsUpdated(statementInput)
    }

    const embargoChanged = this.updateInputValue(embargoInput, embargo)
    if (embargoChanged) {
      changedFields.push(this.data.get('embargoLabel'))
      this.markFieldAsUpdated(embargoInput)
    }

    this.showFieldUpdates(changedFields)

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
    const versionAllowed = version == null || version === '' || currentVersionFound || versionsFound.length === 0
    setTimeout(() => {
      document.dispatchEvent(new CustomEvent('open-access:version-updated', {
        detail: { versionAllowed }
      }))
    }, 0)
  }

  updateInputValue(input, value) {
    if (!input) return false

    const currentValue = this.normalizeValue(input.value)
    const nextValue = this.normalizeValue(value)
    input.value = nextValue

    return currentValue !== nextValue
  }

  normalizeValue(value) {
    return value == null ? '' : String(value)
  }

  showFieldUpdates(changedFields) {
    if (!this.hasFieldUpdatesTarget) return

    if (changedFields.length === 0) {
      this.fieldUpdatesTarget.textContent = ''
      return
    }

    const messageTemplate = this.data.get('fieldsUpdatedMessage')
    const message = messageTemplate.replace(/__FIELDS__/g, this.formatFieldList(changedFields))
    this.fieldUpdatesTarget.textContent = message
  }

  formatFieldList(fields) {
    if (fields.length === 1) return fields[0]
    if (fields.length === 2) return `${fields[0]} ${this.data.get('fieldsConjunction')} ${fields[1]}`

    const leadingFields = fields.slice(0, -1).join(', ')
    const finalField = fields[fields.length - 1]

    return `${leadingFields}, ${this.data.get('fieldsConjunction')} ${finalField}`
  }

  markFieldAsUpdated(input) {
    if (!input) return

    const container = input.closest('.form-wrapper, .mb-3')
    const elementToHighlight = container || input

    elementToHighlight.classList.add('border', 'border-warning', 'rounded-2')

    if (this.clearHighlightHandle) clearTimeout(this.clearHighlightHandle)

    this.clearHighlightHandle = setTimeout(() => {
      document.querySelectorAll('.border-warning.rounded-2').forEach((el) => {
        el.classList.remove('border', 'border-warning', 'rounded-2')
      })
      this.clearHighlightHandle = null
    }, 3000)
  }
}