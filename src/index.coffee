React = require 'react'
ContentEditable = require 'react-contenteditable'

nonNullKeys = (o) ->
    ks = []
    for k, v of o
        if v?
            ks.push k
    ks

parseValue = (s) ->
    if s.match /^\d+$/
        Number s
    else if s in ['true', 'false']
        s == 'true'
    else if s == '{}'
        {}
    else if s == '[]'
        []
    else
        s

EditableField = React.createClass
    getInitialState: ->
        value: @props.value
        edited: false

    componentWillReceiveProps: (new_props) ->
        if new_value = new_props.value
            @setState {value: new_value}

    empty: -> !@state.value?.length

    onChange: (e) ->
        value = e.target.value
        value = parseValue value
        edited = value != @props.value
        @setState {value, edited}

    onKeyDown: (e) ->
        if e.keyCode == 13
            e.preventDefault()
            @save()

    save: ->
        console.log '[EditableField save]', @state
        if @state.edited
            @props.onSave(@state.value)
            @setState {edited: false}
            if @props.clearOnSave
                @setState {value: ''}

    focus: ->
        @refs.input.htmlEl.focus()

    render: ->
        className = (@props.className or '') + ' editable-field' + if @state.edited then ' edited' else ''
        className += ' type-' + typeof @state.value
        if !@props.value?
            className += ' new'
        <div className=className>
            <ContentEditable ref='input' html={asString @state.value} onChange=@onChange disabled=@props.disabled onKeyDown=@onKeyDown placeholder=@props.placeholder onBlur=@save />
            {if @empty()
                <span className='placeholder'>{@props.placeholder}</span>
            }
        </div>

# <input size=1 value=@state.value onChange=@onChange onKeyDown=@onKeyDown placeholder='new value' disabled=@props.disabled />

asString = (value) ->
    if typeof value == 'object'
        JSON.stringify value
    else
        value

NewRow = React.createClass
    displayName: 'NewRow'
    
    getInitialState: ->
        key: if @props.static_key? then @props.static_key else ''
        value: ''
        errors: {}

    componentDidMount: ->
        if @props.static_key?
            @refs.value.focus()
        else
            @refs.key.focus()

    onChange: (key) -> (e) =>
        value = e.target?.value || e
        # if key == 'value'
        #     value = parseValue value
        change = {}
        change[key] = value
        @setState change

    errors: -> {
        key: true if !@state.key.length and !@props.static_key?
    }

    trySave: ->
        console.log '[NewRow trySave]'
        if nonNullKeys(errors = @errors()).length > 0
            @setState {errors}
        else
            @save()

    save: ->
        console.log '[NewRow save]'
        {key, value} = @state
        # value = parseValue value
        row = {}
        row[key] = value
        @props.onSave row
        @setState @getInitialState()
        @refs.key.focus()

    saveKey: (key) ->
        # console.log '[saveKey]', key
        @setState {key}, =>
            if @state.key.length > 0
                @refs.value.focus()

    saveValue: (value) ->
        # console.log '[saveValue]', value
        @setState {value}, =>
            @trySave()

    onKeyDown: (key) -> (e) =>
        if e.keyCode == 13 # ENTER
            e.preventDefault()
            if key == 'key'
                @saveKey()
            else if key == 'value'
                @saveValue()
        if e.keyCode == 8 # BACKSPACE
            if key == 'key'
                if @state.key.length == 0
                    @props.onCancel()
            else if key == 'value'
                if @state.value.length == 0
                    if @props.static_key?
                        @props.onCancel()
                    else
                        @refs.key.focus()

    render: ->
        <div className='new-row'>
            <EditableField
                ref='key'
                className={'key ' + if @state.errors.key then ' invalid' else ''}
                value={@state.key}
                onSave=@saveKey
                disabled={@props.static_key?}
            />
            <EditableField
                ref='value'
                className={'value ' + if @state.errors.value then ' invalid' else ''}
                value={asString @state.value}
                onSave=@saveValue
            />
        </div>

ObjectEditor = React.createClass
    displayName: 'ObjectEditor'

    getInitialState: ->
        object: @props.object
        adding: false

    componentWillReceiveProps: (new_props) ->
        if new_object = new_props.object
            @setState {object: new_object}

    saveRow: (key) -> (value) =>
        {object} = @state
        object[key] = value
        @setState {object}
        @props.onSave object

    saveEntire: (object) ->
        @setState {object}
        @props.onSave object

    updateKey: (old_key) -> (new_key) =>
        {object} = @state
        value = object[old_key]
        delete object[old_key]
        object[new_key] = value
        @setState {object}
        @props.onSave object

    addRow: (row) ->
        console.log "[addRow] #{JSON.stringify row}"
        {object} = @state
        Object.assign object, row
        @setState {object, adding: false}, @focusAdder
        @props.onSave object

    addValue: (row) ->
        value = row[Object.keys(row)[0]]
        console.log "[addValue] #{JSON.stringify value}"
        {object} = @state
        object.push value
        @setState {object, adding: false}, @focusAdder
        @props.onSave object

    deleteRow: (key) -> =>
        console.log "[deleteRow] #{JSON.stringify key}"
        {object} = @state
        if Array.isArray object
            object.splice(key, 1)
        else
            delete object[key]
        @setState {object}
        @props.onSave object

    focusAdder: ->
        @refs.adder.focus()

    showAddRow: ->
        @setState {adding: true}

    hideAddRow: ->
        @setState {adding: false}, @focusAdder

    render: ->
        if typeof @state.object == 'object'
            if Array.isArray @state.object
                editor_class_name = 'array-editor'
            else
                editor_class_name = 'object-editor'

            <div className=editor_class_name>
                {Object.keys(@state.object).map (key) =>
                    value = @state.object[key]
                    <div className='row' key=key>
                        <span className='key'>
                            <EditableField onSave=@updateKey(key) className='key' value=key disabled={Array.isArray @state.object} />
                            {if typeof value == 'object'
                                if Array.isArray value
                                    key_class_name = 'key-extra-array'
                                else
                                    key_class_name = 'key-extra-object'
                                <span className=key_class_name>
                                    {if Array.isArray value
                                        "[ " + value.length + " ]"
                                    else
                                        "{ " + Object.keys(value).length + " }"
                                    }
                                </span>
                            }
                        </span>
                        <ObjectEditor object=value onSave=@saveRow(key) />
                        <div className='actions'>
                            <a onClick=@deleteRow(key) className='delete button'><i className='fa fa-close' /></a>
                        </div>
                    </div>
                }
                {if typeof @state.object == 'object'
                    if @state.adding
                        if Array.isArray @state.object
                            <NewRow onSave=@addValue static_key=@state.object.length onCancel=@hideAddRow />
                        else
                            <NewRow onSave=@addRow onCancel=@hideAddRow />
                    else
                        <button ref='adder' className='adder' onClick=@showAddRow>+</button>
                }
            </div>

        else
            <EditableField className='value value-editor' value=@state.object onSave=@saveEntire />

module.exports = ObjectEditor
