// [Question leading to below topic is as: https://community.rstudio.com/t/add-a-button-into-a-row-in-a-datatable/18651/2 ]
// [ http://www.open-meta.org/technology/one-observer-for-all-buttons-in-shiny-using-javascriptjquery/ ]
// Prepare the event [js.global_btn_clicked] for shiny to observe once any of the HTML element <button> is clicked. (Note: Here the dot sign is a plain character in R)
// Please ensure this code is included at initialization of the app.
// [Below statements as well as codes are quoted from the author of above website link.]
// The code uses a JavaScript programming convention in which global variable names are in all caps.
// BUTTON_CLICK_COUNT is a global so that it doesn’t start over at 1 every time a button gets clicked.
// The first line says to run the embedded function whenever there’s a click on a <button> element in the document.
/*
$(document).on('click', 'button', function(e) {
	// 100.  The next line, which is the first line of the embedded function, tells JavaScript not to bubble the event upward to the <button>’s parent elements.
	// Without this line, the embedded function is called a second time when the event hits the document level.
	e.stopPropagation()
	if(typeof BUTTON_CLICK_COUNT == "undefined") {
		BUTTON_CLICK_COUNT = 1; 
	} else {
		BUTTON_CLICK_COUNT ++;
	}
	// 900. It sends the button’s id to an observer inside Shiny called js.button_clicked.
	//  It appends the BUTTON_CLICK_COUNT onto the button’s id. So, if the button id is view_1 (in this example, view means a View Project button, 1 indicates the the row the button is in),
	//  what the js.button_clicked observer would receive is something like view_1_1.
	Shiny.onInputChange("js.global_btn_clicked", 
	e.target.id + "_" + BUTTON_CLICK_COUNT);
});
*/
// The BUTTON_CLICK_COUNT is just a trick to make sure Shiny thinks the input has changed.
// Without that, sometimes a button will go dead because although Shiny.onInputChange() sees the click, it doesn’t think anything has changed, so it doesn’t send the id back to the server.
// All of the other code in the embedded function does nothing but come up with that number. Once back in Shiny on the server,  the click count is meaningless.
/*
	In your Shiny app, the observer for button clicks might begin like this:
	observeEvent(input$js.global_btn_clicked, {
		uid = str_split(input$js.global_btn_clicked, "_")
		button = uid[[1]][1]
		n = uid[[1]][2]
		# for debugging...
		print(paste0(button, " clicked on row ", n))

		switch(button,
			"view" = {...},
			...
		)
	})
	
	For each type of button you have, you include code in this observer that reacts to the type of button (in this example, View Project or Join Project) and the exact row the button was in (in n).
	And that’s how you can have any number of buttons and just one observer in Shiny server.
*/

// [ http://www.open-meta.org/technology/adding-anchors-to-our-shiny-button-observer/ ]
// Following the above solution, the author distributes a more advanced one that handles <button> and anchors <a> at the same time
// [ http://www.open-meta.org/technology/shiny-button-observer-update-ignoring-clicks-on-disabled-buttons/ ]
// The 3rd post of the same author soloves a case of: ignoring clicks on disabled buttons

// [ https://stackoverflow.com/questions/54109510/uncaught-referenceerror-shiny-is-not-defined ]
// Below solution still needs revamp because it still cannot be called properly
var shinyReady = (function() {
	var callbacks = $.Callbacks();
	$(function() {
		setTimeout(function() {
			callbacks.fire();
			callbacks = null;
		}, 100); // this probably can be 2 since shiny use 1
	});
	return function(callback) {
		if (callbacks) {
			callbacks.add(callback);
		} else {
			callback();
		}
	};
})();

shinyReady(function() {
	$(document).on('click', 'button,a', function(e) {
		// The new code is all in the first if statement, which now looks at the target of each click (ie, the button or link that was clicked on) to see if its list of classes includes disabled. 
		// If so, the click event is trashed and nothing happens.
		if(e.target.className.indexOf("disabled") >= 0) {
			e.stopPropagation();
			return;
		}
		if(e.target.id.length == 0) { return; } // No ID, not ours.
		if(e.target.nodeName == "A" &&
			typeof e.target.href != "undefined" && // If it's a link 
			e.target.href.length > 0) {            // with an href
				return;                            // don't mess with it.
		}
		Shiny.onInputChange("js.omclick", e.target.id + "_" + (new Date()).getTime());
	});
});
/*
LATER: On the other hand, if you add disabled as an attribute, rather than as a class, the browser itself is likely to take care of both the look and ignoring the click,
 so this update isn’t really necessary. But it does allow you to use either method.
 As a class:
<button id="id" class="disabled">...

As an attribute:
<button id="id" disabled>...
*/

// May check the site: https://cloud.tencent.com/developer/ask/201867
