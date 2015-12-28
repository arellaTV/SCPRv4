#= require xml2json

class scpr.ListenLive
    constructor: (options) ->
        # This was old code for a StreamMachine PoC. It is no longer used.

    #----------

    class @CurrentGen
        DefaultOptions:
            url:                "http://live.scpr.org/kpcclive?ua=SCPRWEB&preskip=true"
            player:             "#jquery_jplayer_1"
            swf_path:           "/assets-flash"
            pause_timeout:      300
            schedule_finder:    "#llschedule"
            schedule_template:  JST["t_listen/currentgen_schedule"]
            solution:           "flash, html"
            ad_element:         "#live_ad"
            skip_preroll:       false

        constructor: (opts) ->
            @options = _.defaults opts, @DefaultOptions

            @x2js = new X2JS()

            @player = $(@options.player)
            @_pause_timeout = null

            @_live_ad = $(@options.ad_element)

            @_shouldTryAd = true

            @_on_now = null

            @_playerReady = false

            # -- set up our player -- #

            @player.jPlayer
                swfPath: @options.swf_path
                supplied: "mp3"
                ready: =>
                    @_playerReady = true

            # -- Ad Code -- #

            if @_playerReady
                @_play()
            else
                @player.one $.jPlayer.event.ready, (evt) => @_play()

            # -- register play / pause handlers -- #
            @player.on $.jPlayer.event.play, (evt) =>
                if @_pause_timeout
                    clearTimeout @_pause_timeout
                    @_pause_timeout = null

                if urls = @_impressionURLs
                    @_impressionURLs = null
                    _.each urls, (url) =>      
                        # create an img and append it to our DOM              
                        img = $("<img src='#{url}' style='display: none;'>")
                        @_live_ad.append(img)

            @player.on $.jPlayer.event.pause, (evt) =>

                # set a timer to convert this pause to a stop in one minute
                @_pause_timeout = setTimeout =>
                    @player.jPlayer("clearMedia")
                    @_shouldTryAd = true
                , @options.pause_timeout * 1000

            @player.on $.jPlayer.event.error, (evt) =>
                if evt.jPlayer.error.type == "e_url_not_set"
                    @_play()

            @player.on $.jPlayer.event.ended, (evt) =>
                @_play()

            $.jPlayer.timeFormat.showHour = true;

            # -- build our schedule -- #

            if @options.schedule
                @schedule = new ListenLive.Schedule @options.schedule
                @_buildSchedule()

                setTimeout =>
                    @_buildSchedule() unless @_on_now == @schedule.on_now()
                , 60*1000

        #----------

        _play: ->
            _playStream = _.once =>
                @player.jPlayer("clearMedia")
                @player.jPlayer("setMedia",mp3:@options.url).jPlayer("play")

            if !@_shouldTryAd || @options.skip_preroll
                _playStream()

            else
                @_shouldTryAd = false

                # set a timeout so that we make sure the stream starts playing
                # regardless of whether our preroll works
                _timedOut = false
                _errorTimeout = setTimeout =>
                    _timedOut = true
                    console.log "timed out waiting for ad response"
                    _playStream()
                , 3000

                # hit our ad endpoint and see if there is something to play
                $.ajax
                    type:       "GET"
                    # url: "http://www.mocky.io/v2/567afabe0f00007d201af00e"
                    url: "http://adserver.adtechus.com/?adrawdata/3.0/5511.1/3683959/0/1013/header=yes;cookie=no;adct=text/xml;cors=yes"
                    # url:        "http://adserver.adtechus.com/?adrawdata/3.0/5511.1/3590535/0/0/header=yes;adct=text/xml;cors=yes"
                    dataType:   "xml"
                    xhrFields:
                        withCredentials: true
                    error: (err) =>
                        console.log "ajax error ", err
                    success:    (xml) =>
                        console.log "xml is ", xml
                        @_xml = xml

                        clearTimeout _errorTimeout if _errorTimeout

                        obj = @x2js.xml2json(xml)

                        @_triton = obj

                        class AdResponse
                            constructor: (obj)->
                                # choose DAAST or VAST response
                                # give DAAST higher precedence than VAST
                                @obj = obj.DAAST or obj.VAST or undefined     
                            preroll: ->
                                @ad().Creatives?.Creative?[0]?.Linear
                            ad: ->
                                @obj?.Ad?.InLine
                            renderVisual: (el)->
                                # find the first html or iframe
                                _(@companions()).find (c) =>
                                    switch
                                        when c.HTMLResource?
                                            el?.html(c.HTMLResource.toString())
                                            el.css(margin:"0 auto").width(c._width)
                                        when c.IFrameResource?
                                            el?.html $("<iframe>",src:c.IFrameResource.toString(),width:c._width,height:c._height)
                                            @_submitViewEvent(c)
                                            return true
                                        else
                                            return false
                            impressions: ->
                                # Always return an array, even if there is one or no impressions
                                impressions = @ad().Impression
                                if impressions
                                    if _.isArray(impressions)
                                        parsedImpressions = impressions
                                    else
                                        parsedImpressions = [impressions]
                                else
                                    parsedImpressions = []
                                _.map parsedImpressions, (i) ->
                                    return i.toString()
                            companions: ->
                                @ad().Creatives?.Creative?[1]?.CompanionAds or @ad().Creatives?.Creative?[1]?.CompanionAds?.Companion or []
                            playPreroll: (player)->
                                if preroll = @preroll()
                                    media = preroll.MediaFiles.MediaFile.toString()
                                    player.jPlayer("setMedia",mp3:media).jPlayer("play")     
                            _submitViewEvent: (companion) ->
                                if url = companion.TrackingEvents.Tracking.toString()
                                    $.get("#{url};cors=yes")

                        response = new AdResponse(obj)

                        # is there an ad there for us?
                        if response.ad()
                            # is there a preroll?
                            if response.preroll() && !_timedOut
                                # yes... play it
                                response.playPreroll(@player)
                                @_impressionURLs = response.impressions()
                            else
                                _playStream()
                            # display a visual if there is one
                            response.renderVisual(@_live_ad)
                        else
                            _playStream()

        #----------

        _buildSchedule: ->
            on_now = @schedule.on_now()
            on_next = @schedule.on_at( on_now.end.toDate() ) if on_now

            @_on_now = on_now

            if on_now
                $(@options.schedule_finder).html(
                    @options.schedule_template?(
                        on_now:  on_now.toJSON()
                        on_next: on_next.toJSON()
                    )
                )

                show_link_array = @_on_now.toJSON().link.split( '/' )
                show_slug = show_link_array[4]
                show_splash_img = 'http://media.scpr.org/assets/images/programs/' + show_slug + '_splash@2x.jpg'

                $('.wrapper, .wrapper-backdrop').css('background-image', 'url(' + show_splash_img + ')')



    #----------

    @ScheduleShow: Backbone.Model.extend
        urlRoot: '/api/programs'
        initialize: ->
            # parse start and end times
            @start  = moment 1000 * Number(@attributes['start'])
            @end    = moment 1000 * Number(@attributes['end'])

            # Check if the show starts or ends between hours and choose format
            if @start.format("mm") is "00" and @end.format("mm") is "00"
                time_format = "ha"
            else
                time_format = "h:mma"

            @set
                start:      @start
                end:        @end
                start_time: @start.format(time_format)
                end_time:   @end.format(time_format)

        isWhatsPlayingAt: (time) ->
            @start.toDate() <= time < @end.toDate()

        isPlaying: (state) ->
            @set isPlaying:state

    @Schedule: Backbone.Collection.extend
        model: ListenLive.ScheduleShow

        on_at: (time) ->
            # iterate through models until we get a true result from isWhatsPlayingAt
            @find (m) ->
                m.isWhatsPlayingAt time

        #----------

        on_now: -> @on_at (new Date)

    #----------