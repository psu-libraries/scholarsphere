import { Controller } from 'stimulus'
import axios from 'axios'
import autocomplete from 'autocomplete.js'
import Mustache from 'mustache'

export default class extends Controller {
  static targets = ['field', 'suggestionTemplate', 'emptyResultTemplate', 'lastOptionTemplate']

  connect () {
    const url = this.data.get('search')
    this.ac = autocomplete(
      this.fieldTarget,
      {
        hint: false,
        clearOnSelected: true,
        openOnFocus: true
      },
      [
        {
          source: this.source(url),
          debounce: 200,
          templates: {
            suggestion: (suggestion) => {
              if (!suggestion.last_option) {
                return Mustache.render(this.suggestionTemplateTarget.innerHTML, suggestion)
              } else if (suggestion.last_option && (suggestion.results_length > 0)) {
                return Mustache.render(this.lastOptionTemplateTarget.innerHTML)
              } else {
                return Mustache.render(this.emptyResultTemplateTarget.innerHTML)
              }
            }
          }
        }
      ]
    ).on('autocomplete:selected', (event, suggestion, dataset, context) => {
      event.preventDefault()
      this.element.dispatchEvent(this.afterSelectedEvent(suggestion))
    })
  }

  source (url) {
    return (q, callback) => {
      axios.get(url, { params: { q } }).then((response) => {
        const results = response.data
        results.push(
          { last_option: true, results_length: results.length }
        )
        callback(results)
      })
    }
  }

  afterSelectedEvent (suggestion) {
    return new CustomEvent('autocomplete:after-selected', { bubbles: true, detail: { suggestion: suggestion } })
  }
}
