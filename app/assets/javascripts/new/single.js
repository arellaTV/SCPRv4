scpr.Behaviors.Single = {

    loadBehaviors: function() {



        //  ================================================
        //  Do we support -webkit-filter?
        //  ------------------------------------------------
        //  Credit & thanks & source: http://stackoverflow.com/questions/18986156/detect-support-for-webkit-filter-with-javascript?lq=1
        //  ------------------------------------------------
        //  Which model of "brightness" is being used?
        //  ------------------------------------------------
        //  Credit & thanks & source: http://stackoverflow.com/questions/16303344/brightness-filter-css-safari-vs-chrome
        //  ------------------------------------------------

        if ($(".prologue .ephemera").length) {

        //    var e = document.querySelector("img");
            var e = $(".prologue .ephemera img")[0];
            e.style.webkitFilter = "grayscale(1)";
            if(window.getComputedStyle(e).webkitFilter == "grayscale(1)"){

                // Okay, we're off to the races.
                $("body").addClass("supports-filters");

                // But first, clean up our little test station.
                e.style.webkitFilter = "";


                var oldBrightnessModel = $("<div/>").css("-webkit-filter","brightness(101%)").css("-webkit-filter")==""?true:false;

                if(oldBrightnessModel == true) {
                    $(".prologue .ephemera").addClass("model-old");
                } else {
                    $(".prologue .ephemera").addClass("model-new");
                }

            }

        }




        //  ================================================
        //  Single: An article's first paragraph should be magical
        //  ------------------------------------------------
            if(!$(".prologue").hasClass("austere")) {
                if ($(".report .prose-body p").length) {
                    $(".report .prose p:first").addClass("inaugural");
                }
            }




        //  ================================================
        //  Single Blog: Let's reposition our "POPULAR NOW" box
        //  ------------------------------------------------
            if ($(".popular-on-blog").length) {
                var qtyGrafs    = $(".report .prose-body > p").length;
                var middleInt   = Math.ceil(qtyGrafs / 2);
                var middleEl    = $($(".prose-body > p")[middleInt - 1]) // thanks, bryan!
                $(".popular-on-blog").insertBefore(middleEl);
            }





        //  ================================================
        //  Single: Figure out the orientation of any images
        //  ------------------------------------------------
            if ($(".report .prose img").length) {
                $(window).load(function() { // because WebKit browsers need this in order to *definitely* load/assess the images
                    $(".report .prose img").each(function(){
        //              -------------------------------------------------------------------------
        //              Let's start with all images.
                        var myWidth     = $(this).width();
                        var myHeight    = $(this).height();
                        var myRatio     = myWidth / myHeight;
                        if(myRatio > 1.2)                           { myRatio = "wide"; }
                        if((myRatio <= 1.2) && (myRatio >= 0.9))    { myRatio = "squarish"; }
                        if(myRatio < 0.9)                           { myRatio = "skinny"; }
                        $(this).addClass(myRatio);
        //              --------------------------------------------------------------------------
        //              Now let's specifically act on ones that might appear in an "asset-inset."
                        if($(this).closest(".asset-inset").length > 0) {
                            $(this).closest(".asset-inset").addClass(myRatio);
                        }
                    });
                });
            }






        //  ================================================
        //  Single: Toggle small-viewport caption visibility
        //  ------------------------------------------------
            if ($(".single .caption button").length) {
                $(".caption button").click(function(){
                    if($(this).next().is(":visible")) {
                        $(this).next().slideUp("fast");
                        $(this).html("Caption");
                    } else {
                        $(this).next().slideDown("fast");
                        $(this).html("Hide caption");
                    }
                });
            }




        //  ================================================
        //  Single: IAB Ad Unit stuff
        //  ------------------------------------------------
            if ($("body").hasClass("single") && $(".ad").length) {

                // Okay, the page just loaded.
                // Right now, where should "POSITION A" and "POSITION C" live?
                if ($(".report .supportive").css("float") == "none" ){
                    $(".placard:first").appendTo(".masthead .inner");           // POSITION A
                    $(".placard:last").appendTo(".placard-waystation");         // POSITION C
                }

                // ------------------------------------------------------------------------------------------
                // Now for some (debounced) resizin' checks
                // This function is debounced, and the new, debounced, function is bound to the event.
                function adRepositioner() {
                    if ($(".report .supportive").css("float") == "none" ){
                        $(".placard:first").appendTo(".masthead .inner");       // POSITION A
                        $(".placard:last").appendTo(".placard-waystation");     // POSITION C
                    } else {
                        $(".placard:first").prependTo(".report .supportive");   // POSITION A
                        $(".placard:last").prependTo(".comments .secondary");   // POSITION C
                    }
                };

                // Bind the debounced handler to the resize event.
                $(window).resize( $.debounce( 250, adRepositioner ) );
                // ------------------------------------------------------------------------------------------


            } // end "does this page have an ad?" check






        //  ================================================
        //  Single: Audio-Queue stuff
        //  ------------------------------------------------
            if ($("body").hasClass("single") && $(".audio-queue").length) {

                // Make it do something
                $(".audio-queue a").click(function(){
                    $(".audio-player").show();
                });

                // Cosmetically hide the deck
                $(".audio-player .collapse").click(function(){
                    $(".audio-player").hide();
                });

            }





        //  ================================================
        //  Single: Check up on the curated title length
        //  ------------------------------------------------
            if($("body").hasClass("single")){
                var charcount = $(".prologue h1").html().length;
                if(charcount > 82)                          { $(".prologue .title").addClass("verbose"); }
            }





        //  ================================================
        //  Single: Do we have any audio?
        //  ------------------------------------------------
            if ($(".prose .marginal-tools .audio-queue").length) {
              // This article has an audio clip(s)
            } else {
              $(".prose .marginal-tools").addClass("minimalist");
            }




    } // loadBehaviors

} // Single

