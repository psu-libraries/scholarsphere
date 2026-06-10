import { Application } from 'stimulus'
import OpenAccessVersionController from 'open_access_version_controller'

let subscriptionCallbacks
const mockUnsubscribe = jest.fn()

jest.mock('../../app/javascript/channels/consumer', () => ({
  __esModule: true,
  default: {
    subscriptions: {
      create: jest.fn((_params, callbacks) => {
        subscriptionCallbacks = callbacks
        return { unsubscribe: mockUnsubscribe }
      })
    }
  }
}))

describe('OpenAccessVersionController', () => {
  beforeEach(() => {
    jest.useFakeTimers()
    mockUnsubscribe.mockClear()
    subscriptionCallbacks = undefined

    document.body.innerHTML = `
      <div
        class="tab-pane active show"
        data-controller="open-access-version"
        data-open-access-version-id="123"
        data-open-access-version-accepted-version-value="acceptedVersion"
        data-open-access-version-published-version-value="publishedVersion"
        data-open-access-version-accepted-version-label="accepted version"
        data-open-access-version-published-version-label="published version"
        data-open-access-version-accepted-version-rights="CC BY"
        data-open-access-version-published-version-rights=""
        data-open-access-version-accepted-version-statement="Publisher statement"
        data-open-access-version-published-version-statement=""
        data-open-access-version-accepted-version-embargo="2026-01-01"
        data-open-access-version-published-version-embargo=""
        data-open-access-version-versions-found='["acceptedVersion"]'
        data-open-access-version-not-found-message="Not found"
        data-open-access-version-other-message="We found __OTHER__, not __THIS__"
      >
        <div class="form-wrapper">
          <div data-target="open-access-version.loading" class="d-flex align-items-center mb-2">
            <div class="spinner-border m-4" role="status" aria-hidden="true"></div>
            <span>Determining open access version</span>
          </div>

          <div data-target="open-access-version.controls" class="d-none">
            <div class="form-check mb-2">
              <input
                class="form-check-input"
                type="radio"
                name="work_version[open_access_version]"
                value="acceptedVersion"
                checked
                data-action="change->open-access-version#refresh"
              >
              <label class="form-check-label">Accepted Version</label>
            </div>

            <div class="form-check mb-2">
              <input
                class="form-check-input"
                type="radio"
                name="work_version[open_access_version]"
                value="publishedVersion"
                data-action="change->open-access-version#refresh"
              >
              <label class="form-check-label">Published Version</label>
            </div>

            <span data-target="open-access-version.versionMessage" class="text-danger"></span>
          </div>
        </div>
      </div>

      <input id="work_version_publisher_statement">
      <input id="work_version_work_attributes_embargoed_until">
      <input id="work_version_rights_hidden">
      <select id="work_version_rights">
        <option value="CC BY">CC BY</option>
      </select>
    `

    globalThis.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ open_access_version: 'publishedVersion' })
      })
    )

    const application = Application.start()
    application.register('open-access-version', OpenAccessVersionController)
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  it('autofills fields based on the selected version on connect', () => {
    const radio = document.querySelector('input[value="acceptedVersion"]')
    radio.dispatchEvent(new Event('change', { bubbles: true }))

    expect(document.getElementById('work_version_rights').value).toBe('CC BY')
    expect(document.getElementById('work_version_rights_hidden').value).toBe('CC BY')
    expect(document.getElementById('work_version_publisher_statement').value).toBe('Publisher statement')
    expect(document.getElementById('work_version_work_attributes_embargoed_until').value).toBe('2026-01-01')
  })

  it('shows the version mismatch message when only the other version is found', () => {
    const radio = document.querySelector('input[value="publishedVersion"]')
    radio.checked = true
    radio.dispatchEvent(new Event('change', { bubbles: true }))

    jest.runOnlyPendingTimers()

    const message = document.querySelector('[data-target="open-access-version.versionMessage"]')
    expect(message.textContent).toBe('We found accepted version, not published version')
  })

  it('dispatches open-access:version-updated with versionAllowed', () => {
    const handler = jest.fn()
    document.addEventListener('open-access:version-updated', handler)

    const radio = document.querySelector('input[value="acceptedVersion"]')
    radio.checked = true
    radio.dispatchEvent(new Event('change', { bubbles: true }))

    jest.runOnlyPendingTimers()

    expect(handler).toHaveBeenCalled()
    expect(handler.mock.calls[0][0].detail).toEqual({ versionAllowed: true })
  })

  it('applies the open access version from the channel', () => {
    expect(subscriptionCallbacks).toBeDefined()

    subscriptionCallbacks.received({ id: '123', open_access_version: 'publishedVersion' })

    const published = document.querySelector('input[value="publishedVersion"]')
    expect(published.checked).toBe(true)
  })

  it('ignores channel updates for a different id', () => {
    const published = document.querySelector('input[value="publishedVersion"]')
    // ensure it's not already checked
    published.checked = false
    expect(published.checked).toBe(false)

    subscriptionCallbacks.received({ id: '999', open_access_version: 'publishedVersion' })

    expect(published.checked).toBe(false)
  })

  it('falls back to show controls and unsubscribe after 15s', () => {
    const loading = document.querySelector('[data-target="open-access-version.loading"]')
    const controls = document.querySelector('[data-target="open-access-version.controls"]')
    loading.classList.remove('d-none')
    controls.classList.add('d-none')

    jest.advanceTimersByTime(15_000)

    expect(controls.classList.contains('d-none')).toBe(false)
    expect(loading.classList.contains('d-none')).toBe(true)
    expect(mockUnsubscribe).toHaveBeenCalled()
  })

  it('fetches open access version again at timeout when still loading', () => {
    const loading = document.querySelector('[data-target="open-access-version.loading"]')
    const controls = document.querySelector('[data-target="open-access-version.controls"]')

    loading.classList.remove('d-none')
    controls.classList.add('d-none')

    globalThis.fetch.mockClear()

    jest.advanceTimersByTime(15_000)

    expect(globalThis.fetch).toHaveBeenCalledTimes(1)
    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/dashboard/form/work_versions/123/open_access_version',
      { headers: { Accept: 'application/json' } }
    )
  })

  it('does not fetch again at timeout when loading is already complete', () => {
    const loading = document.querySelector('[data-target="open-access-version.loading"]')
    const controls = document.querySelector('[data-target="open-access-version.controls"]')

    loading.classList.add('d-none')
    controls.classList.remove('d-none')

    globalThis.fetch.mockClear()

    jest.advanceTimersByTime(15_000)

    expect(globalThis.fetch).not.toHaveBeenCalled()
  })

  it('fetches open access version and applies it', async () => {
    await Promise.resolve()
    const published = document.querySelector('input[value="publishedVersion"]')
    expect(published.checked).toBe(true)
  })
})
