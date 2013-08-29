$(document).ready ->
  # A plugin to update a news/activity box dynamically with AJAX (in case web-sockets are not set up/available)
  # e.g. using a redis DB
  # TODO: implement as jQuery function $.fn
  app.streamPoll = 
    options:
      # URL to request JSON data
      pollUrl: "#{location.protocol}//#{location.host}/stream"
      # poll interval
      intervalTime: 10000
      # max items to show
      max: 3
      aniTime: 500
    interval: null
    buffer: []
    
    # add HTML templates. Can vary depending on event type
    getTemplate: ( item ) -> 
      if item.item
        event = item.event.match(/([a-z]+)_created/)
        model = event[1]
        unless model == 'reaction'      
          note = "<a href='#{item.url}'>#{item.title}</a>"

        """
          <li>
            #{item.user.avatar}
            <div class="stream-summary">
              #{note}
            </div>
          </li>
        """
      else """
        <li></li>
      """
    
    init: (options) ->
      @options = $.extend {}, @options, options if options
      # stop animations and interval if box is focussed
      @options.target.mouseenter => 
        $(@).stop()
        @stop_poll() if @interval != null

      # continue on mouseleave
      @options.target.mouseleave =>         
        @start_poll() if @interval == null
      
      @pollUrl = @options.pollUrl
      @setHeight()
      @get()
      @start_poll()

    # start poll interval
    start_poll: ->
      @polling = false
      @interval = self.setInterval => 
        @get()
      , @options.intervalTime

    stop_poll: ->
      self.clearInterval @interval
      @interval = null
    
    isPolling: ->
      @polling

    # request new data
    get: () -> 
      unless @isPolling()
        @polling = true
        $.getJSON @pollUrl, (response, e, status) => 
          response = response.reverse()
          # check if the received data equals the present and skip in case
          unless JSON.stringify(@buffer[0]) == JSON.stringify(response[0]) # status.status == 304
            @buffer = response
            @renderPollResult(response)
          else
            @polling = false
    
    # in case the number or height of items changes, adjust the height of the box
    setHeight: ->
      boxHeight = @options.target.height()
      @options.target.parent().animate({height: boxHeight}, @options.aniTime)

    renderPollResult: (data) ->
      # for each data-set render a html snippet and inject it
      if data.length > 0
        $.each data, (k,v) =>
          unless v.user && v.user.screen_name
            return true #continue
            
          newItem = $(@getTemplate( v ))
          $('.created_at', newItem).timeago()
          newItem.appendTo(@options.target)

        items = @options.target.find('li')
        if items.length > @options.max
          lastItems = items.filter(":lt(#{@options.max  })")
          
          height = 0
          $.each lastItems, (i, el) =>
            height += $(el).height()
            
          @options.target.animate( {bottom: (height * -1 - 30)}, @options.aniTime * lastItems.length, =>
            lastItems.remove()
            @options.target.css({bottom: 0})
            @setHeight()            
          )
        else
          @setHeight()
      @polling = false
  
  streamBox = $('#community-stream')
  unless streamBox.length == 0
    req.streamPoll.init({ intervalTime: 30000, target: streamBox})
