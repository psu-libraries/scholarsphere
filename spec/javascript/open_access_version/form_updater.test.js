import FormUpdater from 'open_access_version/form_updater'

describe('FormUpdater', () => {
  beforeEach(() => {
    jest.useFakeTimers()

    document.body.innerHTML = `
      <div class="form-wrapper">
        <div data-target="open-access-version.fieldUpdates"></div>

        <input id="work_version_publisher_statement" value="Publisher statement">
        <input id="work_version_work_attributes_embargoed_until" value="2026-01-01">
        <select id="work_version_rights">
          <option value="CC BY" selected>CC BY</option>
        </select>
      </div>

      <span data-target="open-access-version.versionMessage"></span>
    `
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  it('renders the auto-updated fields message and highlights the field container when the version changes', () => {
    const data = {
      get: jest.fn((key) => ({
        publishedVersionRights: '',
        publishedVersionStatement: '',
        publishedVersionEmbargo: '',
        rightsLabel: 'License',
        statementLabel: "Publisher's Statement",
        embargoLabel: 'Embargo Date',
        fieldsUpdatedMessage: 'Updated from selected version: <strong>__FIELDS__.</strong>',
        fieldsConjunction: '</strong> and <strong>',
        versionsFound: '["acceptedVersion"]',
        acceptedVersionValue: 'acceptedVersion',
        publishedVersionValue: 'publishedVersion',
        acceptedVersionLabel: 'accepted version',
        publishedVersionLabel: 'published version',
        otherMessage: 'We found __OTHER__, not __THIS__',
        notFoundMessage: 'Not found'
      }[key]))
    }

    const updater = new FormUpdater({
      data,
      versionMessageTarget: document.querySelector('[data-target="open-access-version.versionMessage"]'),
      fieldUpdatesTarget: document.querySelector('[data-target="open-access-version.fieldUpdates"]'),
      onVersionAllowed: jest.fn()
    })

    updater.refresh('publishedVersion')

    const message = document.querySelector('[data-target="open-access-version.fieldUpdates"]').innerHTML
    expect(message).toContain('Updated from selected version:')
    expect(message).toContain('License')
    expect(message).toContain("Publisher's Statement")
    expect(message).toContain('Embargo Date')
    expect(message).toContain('<strong>')
    expect(document.querySelector('.form-wrapper').classList.contains('border-warning')).toBe(true)
  })
})