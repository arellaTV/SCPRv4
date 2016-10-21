# This adjusts the height of the page to fit the content.
# Not the greatest thing in the world, but enables us to 
# very easily arrange items on the homepage using only CSS.
#
# It's mostly an issue on IE and Firefox.  Webkit/Blink based 
# browsers clear the whitespace at the bottom of the page after
# transform:translateY for some reason.

footerEl     = $('.o-footer')
pageAdjuster = =>
  $('.l-page').height footerEl.offset().top + footerEl.height() + parseInt($('.o-footer').css('padding-top'))

$(window).on 'resize', pageAdjuster

# Observe root HTML element for classes added by TypeKit
observer = new MutationObserver pageAdjuster
observer.observe document.querySelector('html'), { attributes: true }

# Observe ads and adjust to them when they load.
observer = new MutationObserver pageAdjuster
observer.observe document.querySelector('.dfp'), { childList: true }
