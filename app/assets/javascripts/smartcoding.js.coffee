Smartcoding = {}

Smartcoding.autoSelectSearch = ->
  window.onload = ->
    keyword = document.getElementById 'keyword'
    keyword.onclick = ->
      @select()

Smartcoding.autoSelectSearch()
