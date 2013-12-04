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
