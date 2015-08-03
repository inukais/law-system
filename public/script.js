
$(function(){
	$(".allCheck").click(function(){
		var items = $(".group").find("input");
		if($(this).is(":checked")) $(items).prop("checked", true);
		else $(items).prop("checked", false);
	});
});


