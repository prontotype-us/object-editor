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
        if !@props.no_type
            value = parseValue value
        edited = value != @props.value
        @setState {value, edited}

    onKeyDown: (e) ->
        if e.keyCode == 13
            e.preventDefault()
            @save()
        else if e.keyCode == 8 # BACKSPACE
            if !@state.value
                e.preventDefault()
                @props.onCancel?()
            else
                console.log 'value', '"' + @state.value + '"', @state.value.length
        @props.onKeyDown?(e)
        e.stopPropagation()

    save: ->
        console.log '[EditableField save]', @state
        if @state.edited
            @props.onSave(@state.value)
            @setState {edited: false}
            if @props.clearOnSave
                @setState {value: ''}

    onFocus: ->
        el = @refs.input.htmlEl
        if el.innerHTML.length
            range = document.createRange()
            sel = window.getSelection()
            range.setStart(el, 1)
            range.collapse(true)
            sel.removeAllRanges()
            sel.addRange(range)

    focus: ->
        el = @refs.input.htmlEl
        el.focus()

    render: ->
        className = (@props.className or '') + ' editable-field' + if @state.edited then ' edited' else ''
        if !@props.no_type
            className += ' type-' + typeof @state.value
        if !@props.value?
            className += ' new'

        <div className=className>
            <ContentEditable ref='input' html={asString @state.value} onChange=@onChange disabled=@props.disabled onKeyDown=@onKeyDown placeholder=@props.placeholder onBlur=@save onFocus=@onFocus />
            {if @empty()
                <span className='placeholder'>{@props.placeholder}</span>
            }
        </div>

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

    focusKey: ->
        console.log 'select?'
        if @props.static_key?
            @onCancel()
        else
            @refs.key.focus()

    render: ->
        <div className='new-row'>
            <EditableField
                ref='key'
                className={'key ' + if @state.errors.key then ' invalid' else ''}
                value={@state.key}
                onSave=@saveKey
                onCancel=@props.onCancel
                disabled={@props.static_key?}
                no_type=true
            />
            <EditableField
                ref='value'
                className={'value ' + if @state.errors.value then ' invalid' else ''}
                value={asString @state.value}
                onSave=@saveValue
                onCancel=@focusKey
            />
        </div>

ObjectEditor = React.createClass
    displayName: 'ObjectEditor'

    getInitialState: ->
        object: @props.object
        adding: false

    componentWillReceiveProps: (new_props) ->
        if new_object = new_props.object
            @setState {object: new_object, adding: false}

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

    selectKeyField: (key) -> =>
        @refs['key-' + key].focus()

    render: ->
        editor_class_name = (@props.className or '') + ' object-editor '
        if Array.isArray @state.object
            editor_class_name += 'edit-array'
        else if typeof @state.object == 'object'
            editor_class_name += 'edit-object'
            if type = @state.object.type
                editor_class_name += ' -type-' + type
        else
            editor_class_name += 'edit-value'
        if key = @props.key_name
            editor_class_name += ' value-' + key

        if typeof @state.object == 'object'
            <div className=editor_class_name>
                {Object.keys(@state.object).map (key) =>
                    value = @state.object[key]
                    row_class_name = 'row row-' + key
                    key_class_name = 'key'
                    key_class_name += ' key-' + key

                    <div className=row_class_name key=key>
                        <span className=key_class_name>
                            <EditableField
                                ref={'key-' + key}
                                onSave=@updateKey(key)
                                onCancel=@deleteRow(key)
                                className='key'
                                value=key
                                disabled={Array.isArray @state.object}
                                no_type=true
                            />

                            {if typeof value == 'object'
                                if Array.isArray value
                                    extra_class_name = 'extra-array'
                                else
                                    extra_class_name = 'extra-object'

                                <span className=extra_class_name>
                                    {if Array.isArray value
                                        "[" + value.length + "]"
                                    else
                                        "{" + Object.keys(value).length + "}"
                                    }
                                </span>
                            }
                        </span>

                        <ObjectEditor object=value onSave=@saveRow(key) key_name=key onCancel=@selectKeyField(key) />
                        <div className='actions'>
                            <a onClick=@deleteRow(key) className='delete button'><i className='fa fa-close' /></a>
                        </div>
                    </div>
                }

                {if typeof @state.object == 'object'
                    if @state.adding
                        if Array.isArray @state.object
                            <NewRow ref='new-row' onSave=@addValue static_key=@state.object.length onCancel=@hideAddRow />
                        else
                            <NewRow ref='new-row' onSave=@addRow onCancel=@hideAddRow />
                    else
                        <button ref='adder' className='adder' onClick=@showAddRow>+</button>
                }
            </div>

        else
            <div className=editor_class_name>
                <EditableField className='value' value=@state.object onSave=@saveEntire onCancel=@props.onCancel />
            </div>

module.exports = ObjectEditor
