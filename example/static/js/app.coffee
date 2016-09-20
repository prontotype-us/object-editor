React = require 'react'
ReactDOM = require 'react-dom'
ObjectEditor = require 'object-editor'

test_object = ['asdf', {
    name: "Jones"
    age: 55
    cats: [
        {
            name: 'Snuffles'
            age: 3
        }
        {
            name: 'Ogley'
            age: 10
        }
    ]
}]

App = React.createClass
    getInitialState: ->
        object: test_object

    updateObject: (object) ->
        console.log '[updateObject]', JSON.stringify object
        @setState {object}

    render: ->
        <ObjectEditor object=@state.object onSave=@updateObject />

ReactDOM.render <App />, document.getElementById 'app'
