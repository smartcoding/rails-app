# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  format = (item) ->
    item.name

  $('#post_origin_list, #post_tag_list').select2
    width: '70%'
    openOnEnter: false
    tags: true
    # when comma is typed, finish current tag typing and move to creating next
    # one
    tokenSeparators: [","]
    id: (object) ->
      object.name
    createSearchChoice: (term) ->
      id: term
      name: term
    # send ajax call if at least 2 characters typed
    minimumInputLength: 2
    # max number of tags
    maximumSelectionSize: 5
    ajax:
      url: ->
        $(this).data('feed-url')
      dataType: 'json'
      quietMillis: 60
      data: (term, page) ->
        q: term # search term
        per_page: 10
        page: page

      results: (data, page) -> # parse the results into the format expected by Select2.
        more = (page * 10) < data.total

        tags_objects = []
        $(data.result).each (index, value) ->
          tags_objects.push
            id: value
            name: value

        results: tags_objects
        more: more
    formatResult: format
    formatSelection: format
    initSelection: (element, callback) ->
      data = []
      $(element.val().split(",")).each (index, value) ->
        value = $.trim value
        data.push
          id: value
          name: value

      callback data

  # Allow changing order of tags
  $("#post_tag_list").select2("container").find("ul.select2-choices").sortable
    containment: 'parent'
    start: ->
      $("#post_tag_list").select2("onSortStart")
    update: ->
      $("#post_tag_list").select2("onSortEnd")

  # Allow changing order of origins
  $("#post_origin_list").select2("container").find("ul.select2-choices").sortable
    containment: 'parent'
    start: ->
      $("#post_origin_list").select2("onSortStart")
    update: ->
      $("#post_origin_list").select2("onSortEnd")
