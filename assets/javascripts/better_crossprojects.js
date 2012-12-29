$(function() {
  //draw activity sparklines on projects/index page
  $(".barchart").peity("bar", { colours: ["#aaa"], min: 0, max: 10,
                                height:20, width: (27*(5+1)-1) });
  //hide/show description of projects
  $("table").on("click", ".project-more-toggle", function(event) {
    if (event.target.tagName != "A") {
      $(this).closest("tr").next().toggle()
    }
  })
  //focus on search field on load
  $("#filter-by-name").focus()
  //filter projects depending on input value
  $("#filter-by-name").on("keyup", function() {
    var needle = $.trim($(this).val().toLowerCase())
    var count = 0
    $(".projects-list .project-name a").each(function() {
      var name = $(this).html().toLowerCase()
      var $elem = $(this).closest('tr')
      if (name.indexOf(needle) >= 0) {
        $elem.show()
        //restablish even/odd alternance
        $elem.removeClass("even")
        $elem.removeClass("odd")
        $elem.addClass(["odd", "even"][count % 2])
        count++
      } else {
        $elem.hide()
        $elem.next().hide()
      }
    })
  })
})
