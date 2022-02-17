import { Application } from 'stimulus'
import ClipboardController from 'clipboard_controller'

Object.assign(navigator, {
  clipboard: {
    writeText: () => jest.fn().mockImplementation(() => Promise.resolve())
  }
})

describe('ClipboardController', () => {
  jest.spyOn(navigator.clipboard, 'writeText')

  beforeEach(() => {
    document.body.innerHTML =
      '<span data-controller="clipboard" data-target="clipboard.source" data-source="test">' +
      '  <button id="btn" data-action="clipboard#copy">' +
      '</span>'

    const application = Application.start()
    application.register('clipboard', ClipboardController)
  })

  it('copies the value to the clipboard when the button is clicked', () => {
    document.getElementById('btn').click()
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('test')
  })
})
