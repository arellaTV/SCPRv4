jQuery(document).ready(function($) {


//	================================================
//	Do we support -webkit-filter?
//	------------------------------------------------
//  Credit & thanks & source: http://stackoverflow.com/questions/18986156/detect-support-for-webkit-filter-with-javascript?lq=1
//	------------------------------------------------
//	Which model of "brightness" is being used?
//	------------------------------------------------
//  Credit & thanks & source: http://stackoverflow.com/questions/16303344/brightness-filter-css-safari-vs-chrome
//	------------------------------------------------

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
    if ($(".report .prose p").length) {
        $(".report .prose p:first").addClass("inaugural");
    }


//  ================================================
//  Single: Let's reposition our "Related" box
//  ------------------------------------------------
    if ($(".report .prose .related").length) {
        var qtyGrafs    = $(".report .prose > p").length;
        var middleInt   = Math.ceil(qtyGrafs / 2);
        var middleEl    = $($(".prose > p")[middleInt - 1]) // thanks, bryan!
        $(".prose .related").insertBefore(middleEl);
    }


//  ================================================
//  Single: Figure out the orientation of any images
//  ------------------------------------------------
    if ($(".report .prose img").length) {
        $(window).load(function() { // because WebKit browsers need this in order to *definitely* load/assess the images
            $(".report .prose img").each(function(){
                var myWidth     = $(this).width();
                var myHeight    = $(this).height();
                var myRatio     = myWidth / myHeight;
                if(myRatio > 1.2)                           { myRatio = "wide"; }
                if((myRatio <= 1.2) && (myRatio >= 0.9))    { myRatio = "squarish"; }
                if(myRatio < 0.9)                           { myRatio = "skinny"; }
                $(this).addClass(myRatio);
            });
        });
    }


//	================================================
//	Single: Audio-trigger stuff
//	------------------------------------------------
    if ($("body").hasClass("single") && $(".audio-trigger").length) {

        // Okay, the page just loaded. Right now, should it live?
        if ($(".report .supportive").css("float") == "none" ){
            $("aside.audio").prependTo(".cubbyhole");
        }

        // Move it around based on screen width
        $(window).resize(function(){
            if ($(".report .supportive").css("float") == "none" ){
                $("aside.audio").prependTo(".cubbyhole");
            } else {
                $("aside.audio").prependTo(".report .supportive");
            }
        });

        // Make it do something
        $(".audio-trigger button").click(function(){
            alert("Wow, you must really want to listen to audio!");
        });


    }



//	================================================
//	Let's wrap text on hyphens
//	------------------------------------------------

    var re = /(.+?)-(.+?)/gi
    var reporters = $(".reporters figure h1 a")

    reporters.each(function() {
        var el = $(this)
        var text = el.html()
        var fixedText = $("<div />").html(text.replace(re, "$1-&#8203;$2")).text()
        el.html(fixedText)
    })




//  ================================================
//  Instatiate FastClick
//  ------------------------------------------------
    $(function() {
        FastClick.attach(document.body);
    });



//  ================================================
//  Landing: Check up on the curated title length
//  ------------------------------------------------
    if($("body").hasClass("landing")){
        var charcount = $(".headline h1 a").html().length;

        if((charcount < 58) && (charcount > 50))        { $(".headline").addClass("concise"); }
        if((charcount < 51))                            { $(".headline").addClass("tiny"); }
    }



//	================================================
//	Show/hide the Ledge
//	------------------------------------------------
	$(".shownav").click(function(){
		$(".kpcc-ledge").animate({
			top: 0
		}, 300, function() {
			// Dropdown complete.
		});
	});
//	................................................
	$(".kpcc-ledge .close").click(function(){
		$(".kpcc-ledge").animate({
			top: "-280px"
		}, 300, function() {
			// Retraction complete.
		});
	});


//	================================================
//	Show/hide the Search
//	------------------------------------------------
	$(".search-trigger").click(function(){
		$(".kpcc-search").animate({
			top: 0
		}, 200, function() {
			// Dropdown complete.
		    $("#q").focus();
		});
	});
//	................................................
	$(".kpcc-search .close").click(function(){
		$(".kpcc-search").animate({
			top: "-130px"
		}, 200, function() {
			// Retraction complete.
		});
	});




}); // end doc ready
