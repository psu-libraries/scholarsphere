import { Controller } from 'stimulus'
import React from 'react'
import ReactDOM from 'react-dom'
import GraphiQL from 'graphiql'

export default class extends Controller {
  connect () {
    const graphQLFetcher = (graphQLParams) => {
      return fetch(this.data.get('endpoint'), {
        method: 'post',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(graphQLParams)
      }).then(response => response.json())
    }

    ReactDOM.render(
      React.createElement(GraphiQL, { fetcher: graphQLFetcher }),
      this.element
    )
  }
}
