import { Application } from 'stimulus'
import InputmaskController from 'inputmask_controller'

describe('InputmaskController', () => {
  beforeEach(() => {
    document.body.innerHTML = '<input data-controller="inputmask" type="text" id="actor_orcid">'

    const application = Application.start()
    application.register('inputmask', InputmaskController)
  })

  it('masks all numeric values', async () => {
    const element = document.getElementById('actor_orcid')

    element.value = '1111111111111111'
    expect(element.value).toBe('1111-1111-1111-1111')
  })

  it('masks uris', async () => {
    const element = document.getElementById('actor_orcid')

    element.value = 'https://orcid.org/0000-0001-9500-0828'
    expect(element.value).toBe('0000-0001-9500-0828')
  })
})
