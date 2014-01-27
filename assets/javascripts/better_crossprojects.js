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
        return remove_accents((elem.textContent || elem.innerText || "").toLowerCase()).indexOf(remove_accents(match[3] || "").toLowerCase()) >= 0;
    }
});

function remove_accents(str) {
    var accent = [
        /[\300-\306]/g, /[\340-\346]/g, // A, a
        /[\310-\313]/g, /[\350-\353]/g, // E, e
        /[\314-\317]/g, /[\354-\357]/g, // I, i
        /[\322-\330]/g, /[\362-\370]/g, // O, o
        /[\331-\334]/g, /[\371-\374]/g, // U, u
        /[\321]/g, /[\361]/g, // N, n
        /[\307]/g, /[\347]/g, // C, c
    ];
    var noaccent = ['A','a','E','e','I','i','O','o','U','u','N','n','C','c'];
    for(var i = 0; i < accent.length; i++){
        str = str.replace(accent[i], noaccent[i]);
    }
    return str;
}
