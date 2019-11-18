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
    const label = this.element.getElementsByTagName('label').item(0).innerText
    for (let count = 1; count < this.inputGroups.length; count++) {
      this.inputGroups.item(count).appendChild(this.removeButton)
    }
    this.element.appendChild(this.addButton(label))
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  add (event) {
    event.preventDefault()
    this.element.insertBefore(this.newField, this.element.lastElementChild)
  }

  // By default, Stimulus listens to click events on buttons and will execute this method.
  remove (event) {
    event.preventDefault()
    event.target.parentElement.remove()
  }

  // @return [HTMLElement] cloned field taken from the first input group.
  get newField () {
    const clone = this.inputGroups.item(0).cloneNode(true)
    Array.from(clone.getElementsByClassName('form-control')).forEach((input) => {
      input.value = ''
    })
    clone.appendChild(this.removeButton)
    return clone
  }

  // @return [HTMLElement]
  addButton (label) {
    const node = document.createElement('button')
    node.setAttribute('data-action', 'multiple-fields#add')
    node.classList.add('btn', 'btn-outline-success', 'btn-sm')
    const content = document.createTextNode('Add another ' + label)
    node.appendChild(content)
    return node
  }

  // @return [HTMLElement]
  get removeButton () {
    const node = document.createElement('button')
    node.setAttribute('data-action', 'multiple-fields#remove')
    node.classList.add('btn', 'btn-outline-danger', 'btn-sm')
    const content = document.createTextNode('Remove')
    node.appendChild(content)
    return node
  }

  // @return [HTMLCollection]
  get inputGroups () {
    return this.element.getElementsByClassName('input-group')
  }
}
