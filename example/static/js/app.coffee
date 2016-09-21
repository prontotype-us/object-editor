React = require 'react'
ReactDOM = require 'react-dom'
ObjectEditor = require 'object-editor'

test_object = {
    person: {
        name: "Test Jones"
        age: 55
        friends: [
            {
                name: "Test Johnson"
                age: 54
            }
        ]
        interests: [
            "sandals"
            "gorgonzola"
            "ritual sacrifice"
        ]
    }
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
    tickets: [
        {
            price: 500.59
            event: "Skrillex and Friends"
            time: "September 10 2009"
        }
        {
            price: 1100.59
            event: "gNs"
            time: "July 01 2190"
        }
        {
            price: 210.11
            event: "Jim and the Wagoners"
            time: "January 50 1900"
        }
    ]
}

App = React.createClass
    getInitialState: ->
        object: test_object

    updateObject: (object) ->
        console.log '[updateObject]', JSON.stringify object
        @setState {object}

    render: ->
        <ObjectEditor object=@state.object onSave=@updateObject />

ReactDOM.render <App />, document.getElementById 'app'
