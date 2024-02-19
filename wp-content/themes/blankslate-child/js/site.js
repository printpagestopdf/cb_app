
(function($) {
	
$('html').click( function(e) {
    if($(e.target).closest('.navbar').length == 0) {
        // click happened outside of .navbar, so hide
        closeMenu();
    }
});
console.log($('.navbar-collapse'));
$('.navbar-collapse').click( function(e) {
	closeMenu();
});

$(document).ready(function () {
$('body').addClass('loaded');
});

function closeMenu() {
	if($('.navbar-collapse').hasClass('show') === true) {
		$('.navbar-collapse').removeClass("show");
	}
}

})( jQuery );

