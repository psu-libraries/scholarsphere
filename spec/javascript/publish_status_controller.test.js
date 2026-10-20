import { Application } from 'stimulus'
import PublishStatusController from 'publish_status_controller'

let subscriptionCallbacks

jest.mock('../../app/javascript/channels/consumer', () => ({
  __esModule: true,
  default: {
    subscriptions: {
      create: jest.fn((_params, callbacks) => {
        subscriptionCallbacks = callbacks
        return { unsubscribe: jest.fn() }
      })
    }
  }
}))

describe('PublishStatusController', () => {
  beforeEach(() => {
    subscriptionCallbacks = undefined
    document.body.innerHTML = `
      <span data-controller="publish-status"
            data-publish-status-id="123"
            data-publish-status-url="/dashboard/form/work_versions/123/publish_status"
            data-publish-status-allow-publish="false"
            data-publish-status-primary-action="publish"
            data-publish-status-accessibility-message="Accessibility checks are processing."
            data-publish-status-version-message="Version is not allowed.">
        <span data-target="publish-status.show_buttons" class="d-none">Publish</span>
        <span data-target="publish-status.help_text"></span>
      </span>
    `
    globalThis.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ allow_publish: true })
      })
    )

    const application = Application.start()
    application.register('publish-status', PublishStatusController)
  })

  it('loads the current status after subscribing', async () => {
    subscriptionCallbacks.connected()
    await Promise.resolve()
    await Promise.resolve()

    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/dashboard/form/work_versions/123/publish_status',
      { headers: { Accept: 'application/json' } }
    )
    expect(document.querySelector('[data-target="publish-status.show_buttons"]').classList.contains('d-none')).toBe(false)
  })

  it('reloads the current status after a work-version status event', async () => {
    subscriptionCallbacks.received({ status_changed: true })
    await Promise.resolve()
    await Promise.resolve()

    expect(globalThis.fetch).toHaveBeenCalledTimes(1)
  })
})