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
  $("#filter-by-values").focus()
  //filter projects depending on input value
  $("#filter-by-values").on("keyup", function() {
    if($(this).val()){
        $(".projects-list > tbody > tr").hide();
        $(".projects-list > tbody > tr:not(.project-more):MyCaseInsensitiveContains('"+$(this).val()+"')").show();
      }else{
        $(".projects-list > tbody > tr:not(.project-more)").show();
        $(".projects-list > tbody > tr.project-more").hide();
      }
  })
})

$.extend($.expr[":"], {
    "MyCaseInsensitiveContains": function(elem, i, match, array) {
        return (elem.textContent || elem.innerText || "").toLowerCase().indexOf((match[3] || "").toLowerCase()) >= 0;
    }
});
