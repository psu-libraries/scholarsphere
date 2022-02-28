import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['field']

  connect () {
    const $select2 = $(this.fieldTarget)
    const endpoint = this.data.get('endpoint')

    $(this.fieldTarget).select2({
      ajax: {
        delay: 250,
        url: endpoint,
        data: (params) => this.buildParams(params),
        dataType: 'json',
        processResults: (data) => {
          // filter out works already in the collection from the search results
          const filteredWorks = data.filter(d => !this.workIdsInCollection().includes(`${d.id}`))

          return {
            results: filteredWorks
          }
        }
      },
      placeholder: ''
    })

    $(this.fieldTarget).on('select2:select', (e) => {
      if (e && e.params && e.params.data) {
        const suggestion = { work_id: e.params.data.id }

        this.element.dispatchEvent(this.afterSelectedEvent(suggestion))

        // clear the selection
        $select2.val(null).trigger('change')
      }
    })
  }

  afterSelectedEvent (suggestion) {
    return new CustomEvent('autocomplete:after-selected', { bubbles: true, detail: { suggestion: suggestion } })
  }

  buildParams (params) {
    const maxDocuments = 50 + this.workIdsInCollection().length

    const queryParameters = {
      q: params.term,
      max_documents: maxDocuments
    }
    return queryParameters
  }

  workIdsInCollection () {
    const workWrappers = $('.js-work-wrapper[data-work-id]:visible')
    return [...workWrappers].map(w => w.dataset.workId)
  }
}
