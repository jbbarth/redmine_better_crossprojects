//cached here for performance reasons
STRIP_HTML_REGEX = new RegExp("<[^>]*>", "g")

function toggleProjectRowGroup(el) {
    var tr = $(el).parents('tr').first();
    var n = tr.next();
    tr.toggleClass('open');
    while (n.length && !n.hasClass('group')) {
        n.toggle();
        var hidden = n.is( ":hidden" )
        n = n.next('tr');
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
  //focus on search field on load
  $("#filter-by-values").focus();

  //filter projects depending on input value
  $("#filter-by-values").on("keyup", function() {

      var visible_projects = [];

      if($(this).val()){
          $(".projects-list > tbody > tr").hide();
          visible_lines = $(".projects-list > tbody > tr:MyCaseInsensitiveContains('"+$(this).val()+"')");
          visible_lines.show();
          for (var i=0; i < visible_lines.length; i++){
              // Look no need to do list[i] in the body of the loop
              visible_projects[i] = visible_lines[i].id.replace('project-line-','');
          }
      }else{
          $(".projects-list > tbody > tr").show();
      }

      $(".export_links").attr('href', function(i, h) {
          if(h.indexOf('projects=') != -1){
              return h.replace( /(visible_projects=).*/ig, '$1'+visible_projects );
          }else{
              return h + (h.indexOf('?') != -1 ? '&visible_projects=' +visible_projects : '?visible_projects=' +visible_projects);
          }
      });

  });
});

$.extend($.expr[":"], {
    "MyCaseInsensitiveContains": function(elem, i, match, array) {
        // We lower case the pattern (match[3]) and the text (elem.textContent
        // or elem.innerText) and remove accents from both
        //
        // The first condition searchs if pattern is in text
        //
        // BUT this is not enough, as textContent and co will remove html tags
        // and produce unexpected matches. For instance if the DOM contains
        // "<div>A<div>B</div></div>", its textContent will be "AB" thus it
        // will match "AB".
        //
        // So the second condition strips HTML from elem.innerHTML and performs
        // the verification again.
        //
        // We don't apply second conditions immediately because it would
        // probably have dramatic performance drawbacks to blindly use regex
        // substitutions hundred times per page.
        return (remove_accents((elem.textContent || elem.innerText || "").toLowerCase()).indexOf(remove_accents(match[3] || "").toLowerCase()) >= 0) && (remove_accents((elem.innerHTML.replace(STRIP_HTML_REGEX, " ")).toLowerCase()).indexOf(remove_accents(match[3] || "").toLowerCase()) >= 0);
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
