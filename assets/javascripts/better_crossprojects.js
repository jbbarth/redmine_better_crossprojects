function toggleProjectRowGroup(el) {
    var tr = $(el).parents('tr').first();
    var n = tr.next();
    tr.toggleClass('open');
    while (n.length && !n.hasClass('group')) {
        n.toggle();
        var hidden = n.is( ":hidden" )
        n = n.next('tr');
        if (n.is(".project-more")){
            if (hidden) {
                n.hide();
            }
            n = n.next('tr')
        }
    }
}

function toggleAllProjectsRowGroups(el) {
    var tr = $(el).parents('tr').first();
    if (tr.hasClass('open')) {
        collapseAllRowGroups(el);
    } else {
        var tbody = $(el).parents('tbody').first();
        tbody.children('tr').each(function(index) {
            if ($(this).hasClass('group')) {
                $(this).addClass('open');
            } else {
                if (!$(this).is(".project-more")){
                    $(this).show();
                }
            }
        });
    }
}

$(function() {
  //hide/show description of projects
  $("table").on("click", ".project-more-toggle", function(event) {
    if (event.target.tagName != "A") {
      $(this).closest("tr").next().toggle()
    }
  })
  //focus on search field on load
  $("#filter-by-project-name").focus()
  //filter projects depending on input value
  $("#filter-by-project-name").on("keyup", function() {
    if($(this).val()){
      $(".projects-list > tbody > tr").not("[data-project-name*="+$(this).val()+"]").hide()
      $(".projects-list > tbody > tr[data-project-name*="+$(this).val()+"]").show()
    }else{
      $(".projects-list > tbody > tr[data-project-name]").show()
    }
  })
})
