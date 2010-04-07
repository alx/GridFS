function pause(millis) {
	var date = new Date();
	var curDate = null;
	do { curDate = new Date(); } 
	while(curDate-date < millis);
}

function initialize_media_uploadify() {
	
	$("#uploadify_media").uploadify({
		'uploader'   : '/flash/uploadify/uploadify.swf',
		'script'     : $("#gridfs_url").val(),
		'cancelImg'  : '/images/cancel.png',
		'auto'       : true,
		'buttonText' : "Upload Image",
		'multi'      : true,
		'fileDataName': 'file',
		'displayData': 'speed',
		'simUploadLimit': 2,
		onSelect : function (evt, queueID, fileObj) {
			
			$("#upload_spinner").show();
			
			var portfolio = $("#new_portfolio").is(':visible') ? $("#new_portfolio").val() : $("#select_portfolio :selected").val();
			var gallery = $("#new_gallery").is(':visible') ? $("#new_gallery").val() : $("#select_gallery :selected").val();
			
			if(portfolio.length == 0) {
				alert("Veuillez sélectionner un portfolio");
				$("#upload_spinner").hide('slow');
				$("#uploadify_media").uploadifyCancel(queueID);
				$("#uploadify_media").uploadifyClearQueue();
				return false;
			}
			
			if(gallery.length == 0) {
				alert("Veuillez sélectionner une gallerie");
				$("#upload_spinner").hide('slow');
				$("#uploadify_media").uploadifyCancel(queueID);
				$("#uploadify_media").uploadifyClearQueue();
				return false;
			}
			
			$('#uploadify_media').uploadifySettings(
				'scriptData',
				{
					'login[username]' : $('#gridfs_username').val(),
					'login[password]' : $('#gridfs_password').val(),
					'metadata[site_name]' : $('#gridfs_site').val(),
					'metadata[app_name]' : 'media',
					'metadata[portfolio]' : portfolio,
					'metadata[gallery_name]' : gallery
				}
			);
	  },
		onError : function (event, queueID, fileObj, errorObj) {
		  $.noticeAdd({'text': "Erreur pendant l'upload (" + errorObj.info + ")", 'type': 'error'});
			$("#upload_spinner").hide('slow');
			tb_remove();
		},
		onComplete : function (event, queueID, fileObj, response, data) {
		  //process response
		  try {
		    var r = JSON.parse(response);
				$.noticeAdd({'text': "Upload terminées.", 'type': 'success'});
				
				var media_metadata = r.media.metadata;
				load_media_list("gallery", media_metadata.gallery_url, media_metadata.portfolio_url);
			} 
			catch(e) {
				$.noticeAdd({'text': "Erreur pendant l'upload (onComplete)", 'type': 'error'});
			}
			$("#upload_spinner").hide('slow');
			$("#uploadForm input").enable();
			tb_remove();
			
			$("#new_portfolio").val("");
			$("#new_gallery").val("");
			
			$("#new_portfolio_input").hide();
			$("#new_gallery_input").hide();
			
			load_upload_form();
		}
	});
}

/*
* Actions on media items
*/

function request_media(action, media_id, metadatas){
	var json_url = $("#gridfs_url").val() + "/" + action + "/" + media_id;
	json_url += "?login%5Busername%5D=" + $('#gridfs_username').val();
	json_url += "&login%5Bpassword%5D=" + $('#gridfs_password').val();
	
	$.each(metadatas, function(key, value){
		json_url += "&metadata%5B" + key + "%5D=" + value;
	});
	
	json_url += "&callback=?";
	$.getJSON(json_url);
}

function delete_media(media_id){
	request_media("delete", media_id, {});
	load_upload_form();
}

function edit_media(media_id, metadatas){
	request_media("edit", media_id, metadatas);
}

/*
* Sorting
*/

function sortByName(a, b){
	return $(a).text().toLowerCase() > $(b).text().toLowerCase() ? 1 : -1;  
}

function sortByFilename(a, b){
	return $("img", a).attr("alt").toLowerCase() > $("img", b).attr("alt").toLowerCase() ? 1 : -1;  
}

function order_media_list(){
		// Create gallery url
		var folder_url = $("#gridfs_url").val() + "/site/";
		folder_url += $('#currentSite').val();
		folder_url += "/media/folder/";
		folder_url += $("#curentFolderId").val();
		var ordered_list = [];
		
		var order_mode = $("#order_by").val();
		
		$("#order_spinner").show();
		
		switch (order_mode){
		case "manually":
			// Replace value for request format
			ordered_list = $("#media_list")
										.sortable('serialize')
										.replace(/media\[\]=/g,'')
										.split("&");
		break;
		case "by_name":
			$.each($(".media_item").sort(sortByName), function(){
				ordered_list.push(this.id.split("_").pop())
			});
		break;
		case "by_filename":
			$.each($(".media_item").sort(sortByFilename), function(){
				ordered_list.push(this.id.split("_").pop())
			});
		break;}
		
		// edit each media with new order
		var order_num = 0;
		$.each(ordered_list, function(){
			edit_media(this, {'order': order_num});
			order_num += 1;
		});
		
		if(order_mode != "manually"){
			load_media_list("gallery", $('#gallery_id').val());
		}	
		$("#order_spinner").hide();
}

function load_media_list(display_mode, parameter, portfolio_url){
	
	var current_site = $("#gridfs_site").val();
	var site_url = $("#gridfs_url").val() + "/" + current_site + "/";
	//site_url = "http://localhost:4567/" + current_site + "/";
	var thumb_url = site_url + "100/";
	var media_url = "";
	
	switch (display_mode){
		case "portfolios":
			media_url = site_url + "portfolios";
		break;
		case "portfolio":
			media_url = site_url + "portfolio/" + parameter;
		break;
		case "gallery":
			if(portfolio_url == undefined){
				portfolio_url = $("#portfolio_id").val();
			}
			media_url = site_url + "portfolio/" + portfolio_url + "/gallery/" + parameter;
		break;
		case "media":
			media_url = site_url + "media/" + parameter;
		break;
	}
	
	$.ajax({
		url: media_url,
		dataType: 'jsonp',
		error: function(data, textStatus, XMLHttpRequest){
			load_media_list("portfolios", "");
		},
		success: function(data, textStatus, XMLHttpRequest) {
			var response_display = "";
			
			switch (display_mode){
				case "portfolios":
					response_display += "<ul id='crumbs'><li>Portfolios</li></ul>";
					
					$.each(data, function(){
						if(this.id != null && this.name != "null"){
							response_display += "<div class='thumbwrapper portfolio_item' id='portfolio_" + this.id + "'>";
							response_display += "<a href='#' class='highslide open_portfolio' rel='" + this.url + "'>";
							response_display += "<img style='margin-top: 15px' width='100' height='75' src='" + thumb_url + this.thumb + "'>";
							response_display += "</a><br><span>" + this.name + "</span></div>";
						}
					});
				break;
				case "portfolio":
				
					response_display += "<ul id='crumbs'><li><a href='#' id='nav_portfolios' class='open_portfolios'>Portfolios</a></li>";
					response_display += "<li>Portfolio: <input type='text' value='" + data.name + "' id='portfolio_name'>";
					response_display += "<input type='hidden' value='" + data.id + "' id='portfolio_id'></li>";
					
					// Button to delete current portfolio
					response_display += "<li style='padding-left:500px'><input type='button' value='Supprimer le Portfolio' id='delete_portfolio'/><li>";
					response_display += "</ul>";
					
					$('#select_portfolio').val(data.id);
					
					$.each(data.galleries, function(){
						response_display += "<div class='thumbwrapper gallery_item' id='gallery_" + this.name + "'>";
						response_display += "<a href='#' class='highslide open_gallery' rel='" + this.url + "'>";
						response_display += "<img style='margin-top: 15px' width='100' height='75' src='" + thumb_url + this.thumb + "'><br><span>" + this.name + "</span>";
						response_display += "</a></div>";
					});
					
					break;
				case "gallery":
				
					response_display += "<ul id='crumbs'><li><a href='#' id='nav_portfolios' class='open_portfolios'>Portfolios</a></li>";
					response_display += "<li><a href='#' id='nav_portfolio' class='open_portfolio' rel='" + data.portfolio_url + "'>Portfolio: " + data.portfolio + "</a></li>";
					response_display += "<li>Gallery: <input type='text' value='" + data.name + "' id='gallery_name'>";
					response_display += "<input type='hidden' value='" + data.id + "' id='gallery_id'></li>";
					
					// Use select for ordering
					response_display += "<li><select id='order_by'>";
					response_display += "<option class='default_option'>Trier...</option>";
					response_display += "<option>---</option>";
					response_display += "<option value='manually'>manuellement</option>";
					response_display += "<option value='by_name'>par nom</option>";
					response_display += "<option value='by_filename'>par nom de fichier</option>";
					response_display += "</select></li>";
					
					// Button to delete current gallery
					response_display += "<li style='padding-left:150px'><input type='button' value='Supprimer la Gallerie' id='delete_gallery'/><li>";
					
					response_display += "</ul>";
					
					$('#select_gallery').val(data.name);
					
					response_display += "<div id='media_list'>";
					$.each(data.medias, function(){
						
						var media_name = this.filename;
						if(this.metadata.name != undefined){
							media_name = this.metadata.name;
						}
						
						response_display += "<div class='thumbwrapper media_item' id='media_" + this.id + "'>";
						response_display += "<span class='sort ui-icon ui-icon-arrowthick-2-n-s' style='display:none;'></span>";
						response_display += "<a href='#' class='highslide open_media' rel='" + this.id + "'>";
						response_display += "<img style='margin-top: 15px' width='100' height='75' src='" + thumb_url + this.filename + "' alt='" + this.filename + "'><br><span>" + media_name + "</span></a>";
						response_display += "</div>";
					});
					response_display += "</div>";
					
					break;
				case "media":
				
					var media_name = data.filename;
					if(data.metadata.name != undefined){
						media_name = data.metadata.name;
					}
					
					var media_description = "";
					if(data.metadata.description != undefined){
						media_description = data.metadata.description;
					}
				
					response_display += "<ul id='crumbs'><li><a href='#' id='nav_portfolios' class='open_portfolios'>Portfolios</a></li>";
					response_display += "<li><a href='#' id='nav_portfolio' class='open_portfolio' rel='" + data.metadata.portfolio_url + "'>Portfolio: " + data.metadata.portfolio + "</a></li>";
					response_display += "<li><a href='#' id='nav_gallery' class='open_gallery' rel='" + data.metadata.gallery_url + "'>Gallery: " + data.metadata.gallery_name + "</a></li>";
					response_display += "<li id='nav_media'>" + media_name + "</li>";
					response_display += "</ul>";
					
					response_display += "<div id='media_detail_" + data.id + "' class='media_detail'>";
					response_display += "<img width='300' src='" + site_url + "300/" + data.filename + "' alt='" + media_name + "'/>";
					response_display += "<p><label for='media_name'>Nom du media</label><br><input name='media_name' id='media_name' type='text' value='" + media_name + "'/></p>";
					response_display += "<p><label for='media_description'>Description</label><br><textarea name='media_description' id='media_description' cols='40' rows='6'>" + media_description + "</textarea></p>";
					response_display += "<p><a href='#' class='modify_media' rel='"+ data.id + "'>Modifier</a> - "
					
					if($("#media_content .media_item").size() == 1){
						response_display += "<a href='#' id='delete_media_gallery' rel='"+ data.id + "'>Effacer</a></p>";
					} else {
						response_display += "<a href='#' id='delete_media' rel='"+ data.id + "'>Effacer</a></p>";
					}
					
					response_display += "</div>";
			}
			
			$("#media_content").html(response_display);
			
			if(display_mode == "gallery" && $("#order_by").val() == "manually"){
				$("#media_list").sortable({handle:'span.sort'});
			}
	  }
	});
}

function load_upload_form(){
	var site_url = $("#gridfs_url").val() + "/" + $("#gridfs_site").val();
	
	$('#select_portfolio').html("<option value=''>S&eacute;lectionner un portfolio</option><option>----</option><option value='add_portfolio'>Ajouter un portfolio</option><option>----</option>");
	$('#select_gallery').html("<option value=''>S&eacute;lectionner une gallerie</option><option>----</option><option value='add_gallery'>Ajouter une gallerie</option><option>----</option>");
	
	$.getJSON(site_url + "/portfolios?callback=?",
		function(data, status, request) {
			$.each(data, function(){
				populate_select_portfolio(this);
				$.getJSON(site_url + "/portfolio/" + this.url + "?callback=?",
					function(data, status, request) {
						$.each(data.galleries, function(){
							populate_select_gallery(this);
						});
						$('#select_gallery').val($("#gallery_id").val());
					}
				);
				$('#select_portfolio').val($("#nav_portfolio").attr('rel'));
			});
		}
	);
}

function populate_select_portfolio(data){
	if(data.id != null && data.name != "null"){
		$('#select_portfolio').append($("<option></option>").attr("value",data.id).text(data.name));
	}
}

function populate_select_gallery(data){
	if(data.url != null && data.name != "null"){
		$('#select_gallery').append($("<option></option>").attr("value",data.url).text(data.name));
	}
}

$(document).ready(function() {
	
	if($("#uploadify_media").length > 0){
		initialize_media_uploadify();
	}
	
	if($("#media_content").length > 0){
		load_media_list("portfolios", "");
	}
	
	if($('#select_portfolio').length > 0){
		load_upload_form();
	}
	
	if($('#select_gallery').length > 0){
		
		$('#select_gallery').show();
	}
	
	$(".open_portfolios").livequery('click',function(event) {
		load_media_list("portfolios", "");
	});
	
	$(".open_portfolio").livequery('click',function(event) {
		load_media_list("portfolio", this.rel);
	});
	
	$(".open_gallery").livequery('click',function(event) {
		load_media_list("gallery", this.rel);
	});
	
	$(".open_media").livequery('click',function(event) {
		load_media_list("media", this.rel);
	});
	
	$("#order_by").livequery('change', function() {
		if($("#order_by").val() == "manually"){
			$("span.sort").show();
			$("#media_list").sortable({
				handle:'span.sort',
				update: function(event, ui) {
					order_media_list();
				}
			});
		} else {
			$("span.sort").hide();
			$("#media_list").sortable('disable');
			order_media_list();
		}
	});
	
	$("#gallery_name").livequery('change',  function() {
		
		// To change gallery name, we collect all the media displayed in the current view
		// and we edit them with the new gallery name
		$.each($('.media_item'), function(){
			var media_id = this.id.split("_").pop();
			edit_media(media_id, {'gallery_name': $('#gallery_name').val()});
		});
	});
	
	$("#portfolio_name").livequery('change',  function() {
		var gallery_url = $("#gridfs_url").val() + "/" + $("#gridfs_site").val() + "/gallery/";
		
		// To change the portfolio name, we collect all the galleries displayed in the current view
		// then we fetch their medias, and we apply the new portfolio name to each media
		$.each($('.gallery_item a'), function() {
			$.getJSON(gallery_url + this.rel + "?callback=?",
				function(data, status, request) {
					$.each(data.medias, function(){
						edit_media(this.id, {'portfolio': $('#portfolio_name').val()});
					});
				}
			);
		});
	});
	
	$("#delete_portfolio").livequery('click',  function() {
		if(confirm('Confirmer la suppression ?')){
			$.getJSON($("#gridfs_url").val() + "/" + $("#gridfs_site").val() + "/portfolio/" + $("#portfolio_id").val() + "/delete?callback=?", function(){
				pause(500);
				load_media_list("portfolios", "");
			});
		}
	});
	
	$("#delete_gallery").livequery('click',  function() {
		if(confirm('Confirmer la suppression ?')){
			$.getJSON($("#gridfs_url").val() + "/" + $("#gridfs_site").val() + "/portfolio/" + $("#nav_portfolio").attr('rel') + "/gallery/" + $("#gallery_id").val() + "/delete?callback=?", function(){
				pause(500);
				load_media_list("portfolio", $("a#nav_portfolio").attr("rel"));
			});
		}
	});
	
	$('#delete_media').livequery('click',function(event) {
		if(confirm('Confirmer la suppression ?')){
			delete_media(this.rel);
			pause(500);
			load_media_list("gallery", $("a#nav_gallery").attr("rel"), $("a#nav_portfolio").attr("rel"));
		}
	});
	
	$('#delete_media_gallery').livequery('click',function(event) {
		if(confirm('Confirmer la suppression ?')){
			delete_media(this.rel);
			pause(500);
			load_media_list("portfolio", $("a#nav_portfolio").attr("rel"));
		}
	});
	
	$('.modify_media').livequery('click',function(event) {
		
		var media_id = this.rel;
		var media_name = $('#media_name').val();
		var media_description = $('#media_description').val();
		
		edit_media(this.rel, 
			{'name': media_name,
			 'description': media_description});
		
		$("li#nav_media").html(media_name);
	});
	
	$("#select_portfolio").livequery("change", function(){
		if($("#select_portfolio").val() == "add_portfolio"){
			$("#new_portfolio_input").show();
		} else {
			$("#new_portfolio_input").hide();
		}
	});
	
	$("#select_gallery").livequery("change", function(){
		if($("#select_gallery").val() == "add_gallery"){
			$("#new_gallery_input").show();
		} else {
			$("#new_gallery_input").hide();
		}
	});
}); 
