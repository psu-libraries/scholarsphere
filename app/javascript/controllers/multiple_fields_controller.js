// Implements multiple fields in our forms by adding DOM elements to add and remove cloned fields
// in the form. Relies heavily on Bootstrap's form elements. Including the proper data attributes
// will trigger the insertion of the buttons to manage the additional fields. Certain html elements
// are required, such as a label and the input-group css class.
// @example
//   <div class="form-group" data-controller="multiple-fields">
//     <!-- A label is required in order for the buttons to display correctly -->
//     <label>
//       Identifier
//     </label>
//     <!-- The input-group and form=control classes are required in order for new fields to be added -->
//     <div class="input-group">
//       <input class="form-control" />
//   </div>

import { Controller } from 'stimulus'

export default class extends Controller {
  connect () {
    this.baseLabelText = this.element.getElementsByTagName('label').item(0).innerText
    this.firstInput = this.cloneFirstInput()

    for (let count = 1; count < this.inputGroups.length; count++) {
      this.inputGroups.item(count).appendChild(this.removeButton)
    }
    this.inputGroups.item(0).appendChild(this.addButton())
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  add (event) {
    event.preventDefault()
    this.element.appendChild(this.newField)
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  remove (event) {
    event.preventDefault()
    event.target.parentElement.parentElement.remove()
  }

  // @return [HTMLElement] cloned field taken from the first input group.
  get newField () {
    const clone = this.firstInput.cloneNode(true)
    clone.appendChild(this.removeButton)
    return clone
  }

  // @return [HTMLElement]
  addButton () {
    const node = document.createElement('a')
    node.setAttribute('href', '#')
    node.setAttribute('data-action', 'multiple-fields#add')
    node.classList.add('add')

    const description = this.descriptionText('add another')
    node.appendChild(description)

    const icon = this.materialIcon('add_circle_outline')
    node.appendChild(icon)

    return node
  }

  // @return [HTMLElement]
  get removeButton () {
    const node = document.createElement('a')
    node.setAttribute('href', '#')
    node.setAttribute('data-action', 'multiple-fields#remove')
    node.classList.add('remove')

    const description = this.descriptionText('remove')
    node.appendChild(description)

    const icon = this.materialIcon('highlight_off')
    node.appendChild(icon)

    return node
  }

  // @return [HTMLElement]
  materialIcon (text) {
    const icon = document.createElement('i')
    icon.classList.add('material-icons')
    icon.setAttribute('aria-hidden', 'true')
    icon.appendChild(document.createTextNode(text))
    return icon
  }

  // @return [HTMLElement]
  descriptionText (text) {
    const element = document.createElement('span')
    element.classList.add('sr-only')
    element.appendChild(document.createTextNode(text))
    return element
  }

  // @return [HTMLCollection]
  get inputGroups () {
    return this.element.getElementsByClassName('js-multiple-field-group')
  }

  // @return [HTMLElement]
  cloneFirstInput () {
    const firstInput = this.inputGroups.item(0).cloneNode(true)
    Array.from(firstInput.getElementsByClassName('form-control')).forEach((input) => {
      input.value = ''
    })
    return firstInput
  }
}
