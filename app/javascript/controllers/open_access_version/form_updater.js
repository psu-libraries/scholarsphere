const RIGHTS_INPUT_ID = 'work_version_rights'
const RIGHTS_HIDDEN_ID = 'work_version_rights_hidden'
const STATEMENT_INPUT_ID = 'work_version_publisher_statement'
const EMBARGO_INPUT_ID = 'work_version_work_attributes_embargoed_until'

export default class FormUpdater {
  constructor({ data, versionMessageTarget, fieldUpdatesTarget, onVersionAllowed }) {
    this.data = data
    this.versionMessageTarget = versionMessageTarget
    this.fieldUpdatesTarget = fieldUpdatesTarget
    this.onVersionAllowed = onVersionAllowed
  }

  disconnect() {
    if (!this.clearHighlightHandle) return

    clearTimeout(this.clearHighlightHandle)
    this.clearHighlightHandle = null
  }

  refresh(version) {
    const rights = this.data.get(`${version}Rights`)
    const statement = this.data.get(`${version}Statement`)
    const embargo = this.data.get(`${version}Embargo`)

    const statementInput = document.getElementById(STATEMENT_INPUT_ID)
    const embargoInput = document.getElementById(EMBARGO_INPUT_ID)
    const rightsHidden = document.getElementById(RIGHTS_HIDDEN_ID)
    const rightsInput = document.getElementById(RIGHTS_INPUT_ID)

    const changedFields = []

    const rightsChanged = this.#updateInputValue(rightsInput, rights)
    this.#updateInputValue(rightsHidden, rights)
    if (rightsChanged) {
      changedFields.push(this.data.get('rightsLabel'))
      this.#markFieldAsUpdated(rightsInput)
    }

    const statementChanged = this.#updateInputValue(statementInput, statement)
    if (statementChanged) {
      changedFields.push(this.data.get('statementLabel'))
      this.#markFieldAsUpdated(statementInput)
    }

    const embargoChanged = this.#updateInputValue(embargoInput, embargo)
    if (embargoChanged) {
      changedFields.push(this.data.get('embargoLabel'))
      this.#markFieldAsUpdated(embargoInput)
    }

    this.#showFieldUpdates(changedFields)
    this.#updateVersionMessage(version)
  }

  #updateInputValue(input, value) {
    if (!input) return false

    const currentValue = this.#normalizeValue(input.value)
    const nextValue = this.#normalizeValue(value)
    input.value = nextValue

    return currentValue !== nextValue
  }

  #normalizeValue(value) {
    return value == null ? '' : String(value)
  }

  #showFieldUpdates(changedFields) {
    if (!this.fieldUpdatesTarget) return

    if (changedFields.length === 0) {
      this.fieldUpdatesTarget.textContent = ''
      return
    }

    const messageTemplate = this.data.get('fieldsUpdatedMessage')
    const message = messageTemplate.replace(/__FIELDS__/g, this.#formatFieldList(changedFields))
    this.fieldUpdatesTarget.textContent = message
  }

  #formatFieldList(fields) {
    if (fields.length === 1) return fields[0]
    if (fields.length === 2) return `${fields[0]} ${this.data.get('fieldsConjunction')} ${fields[1]}`

    const leadingFields = fields.slice(0, -1).join(', ')
    const finalField = fields[fields.length - 1]

    return `${leadingFields}, ${this.data.get('fieldsConjunction')} ${finalField}`
  }

  #markFieldAsUpdated(input) {
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

  #updateVersionMessage(version) {
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

    const versionAllowed = version == null || version === '' || currentVersionFound || versionsFound.length === 0
    setTimeout(() => {
      this.onVersionAllowed(versionAllowed)
    }, 0)
  }
}